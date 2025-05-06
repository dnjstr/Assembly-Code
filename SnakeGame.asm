.data

    ### MEMORY
    squares:         .space  8192           # 2048 squares x 4 bytes = 8192 bytes
                                            # Note: every square has 8 hex characters
                                            # First 2 chars is direction code (00, 01, 02, 03)
                                            # 6 lower chars is color code in hex
    bgcolor:        .word   0xcefad0        # light green
    wallcolor:      .word   0x008631        # dark green
    snakecolor:     .word   0x0000ff        # blue
    foodcolor:      .word   0xff0000        # red
    up:             .word   0x01000000      # direction code for up
    down:           .word   0x02000000      # direction code for down 
    left:           .word   0x03000000      # direction code for left
    right:          .word   0x04000000      # direction code for right
    gameOverStr:    .asciiz "Game over! Your score: "
    endline:        .asciiz "\n"
    askPlayer:      .asciiz "\nDo you want to play again?"
    
    # Keyboard input variables
    lastInput:      .word   0               # Last keyboard input
    inputPrompt:    .asciiz "\nControls: w=up, s=down, a=left, d=right, q=quit"
    quitMsg:        .asciiz "\nQuitting game... Thanks for playing!\n"
    connectionLostMsg: .asciiz "\nConnection to keyboard/display lost. Exiting program.\n"
    startMsg:       .asciiz "\nSnake Game Started! Use w/a/s/d to change direction.\n"

    ### REGISTER
    # $s0 = score
    # $s1 = address of the head square in memory
    # $s2 = address of the tail square in memory
    # $s3 = current direction
    # $s4 = connection status (0 = connected, 1 = disconnected)
    # $s5 = food eaten flag (1 = food eaten, 0 = no food eaten)
    
### KEYBOARD MMIO ADDRESSES
    # 0xffff0000 - Receiver Control (bit 0 = ready bit)
    # 0xffff0004 - Receiver Data (contains the input character)

.text

####################### BEGIN FUNCTION #######################
### LOAD INTIAL GAME STATE
begin:
    li  $s0, 0              # reset points before new game
    li  $s5, 0              # reset food eaten flag
    lw  $s3, right          # set initial direction to right
    li  $s4, 0              # reset connection status (0 = connected)
    sw  $zero, lastInput    # reset user input
                            # $s1 and $s2 will be reset in draw procedure

### DRAW BACKGROUND
    la  $t0, squares        # load base address
    li  $t1, 2048           # number of squares
    lw  $t2, bgcolor        # load background color: light green
loop1:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, loop1          # keep drawing if no of squares > 0


### DRAW WALL
    # Variables for top wall
    la $t0, squares         # load base address
    li $t1, 64              # number of squares in a row
    lw $t2, wallcolor       # load wall color: dark green
drawTopWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawTopWall    # keep drawing if no of squares > 0

    # Variables for bottom wall
    la  $t0, squares            # load base address
    add $t0, $t0, 7936          # move to the bottom left corner (31*256)
    li  $t1, 64                 # number of squares in a row
drawBottomWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 4         # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawBottomWall # keep drawing if no of squares > 0

    # Variables for left wall
    la  $t0, squares            # load base address
    add $t0, $t0, 256           # move to the first column, top second square
    li  $t1, 30                 # number of squares in a column - 2
drawLeftWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 256       # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawLeftWall   # keep drawing if no of squares > 0

    # Variables for right wall
    la  $t0, squares            # load base address
    add $t0, $t0, 508           # move to the last column, top second square
    li  $t1, 30                 # number of squares in a column - 2
drawRightWall:
    sw      $t2, 0($t0)         # load color to square
    add     $t0, $t0, 256       # advance to squares' next address
    add     $t1, $t1, -1        # decrement number of squares to draw
    bnez    $t1, drawRightWall  # keep drawing if no of squares > 0


### DRAW INITIAL SNAKE, SET INITIAL VALUE TO HEAD AND TAIL
    la  $t0, squares        # load base address
    add $t0, $t0, 3964      # move to middle of the screen
    add $s1, $t0, $zero     # set initial head address
    lw  $t1, snakecolor     # load snake color
    sw  $t1, 0($t0)         # load color to square

    lw  $t2, right          # right value
    or  $t1, $t1, $t2       # square value = color + direction (using OR operation)
    sw  $t1, -4($t0)        # load square value to square
    sw  $t1, -8($t0)        # load square value to square

    add $t0, $t0, -8        # set initial tail address
    add $s2, $t0, $zero

### DRAW INITIAL FOOD
    jal randomFoodLocation

### SHOW CONTROLS AND START THE GAME
    # Display start message with controls
    li $v0, 4
    la $a0, startMsg
    syscall
    
    # Display input controls
    li $v0, 4
    la $a0, inputPrompt
    syscall
    
    j   gameLoop

#################### SNAKE FUNCTION ########################
updateHead:
### SET OLD HEAD DIRECTION
    lw  $t0, 0($s1)             # load head value
    li  $t1, 0x00ffffff         # mask to preserve color bits
    and $t0, $t0, $t1           # clear direction bits
    or  $t0, $t0, $s3           # add direction to value (using OR operation)
    sw  $t0, 0($s1)             # put value back
### UPDATE NEW HEAD POSITION
    lw  $t0, up
    beq $s3, $t0, moveHeadUp
    lw  $t0, down
    beq $s3, $t0, moveHeadDown
    lw  $t0, left
    beq $s3, $t0, moveHeadLeft
    lw  $t0, right
    beq $s3, $t0, moveHeadRight
    j   gameLoop                # Invalid direction, go back to game loop

moveHeadUp:
    add $s1, $s1, -256          # move 64 squares back x 4 bytes
    j   checkCollision
moveHeadDown:
    add $s1, $s1, 256           # move 64 squares forward x 4 bytes
    j   checkCollision
moveHeadLeft:
    add $s1, $s1, -4            # move 1 squares back x 4 bytes
    j   checkCollision
moveHeadRight:
    add $s1, $s1, 4             # move 1 squares forward x 4 bytes
    j   checkCollision

### CHECK COLLISION
checkCollision:
    lw  $t0, 0($s1)             # load color of the head snake square b4 drawing
    lw  $t1, foodcolor          # load food color
    beq $t0, $t1, foodEvent     # branch if new head == food
    lw  $t1, bgcolor            # load background color
    beq $t0, $t1, cont          # continue if head == background color

    # If we get to here it means head == wallcolor or snakecolor
    j   gameOver

### DELETE OLD TAIL AND UPDATE NEW TAIL
cont:
    # Set food eaten flag to 0 (no food eaten this move)
    li  $s5, 0
    
    lw  $t0, 0($s2)             # get old tail value
    li  $t1, 0xff000000
    and $t0, $t0, $t1           # get the first 2 bytes (direction of old tail)
                                # to move to the next tail
    # DELETE OLD TAIL
    lw  $t1, bgcolor            
    sw  $t1, 0($s2)             # set old tail == bgcolor

    # UPDATE NEW TAIL
    lw  $t1, up                 
    beq $t0, $t1, moveTailUp    
    lw  $t1, down
    beq $t0, $t1, moveTailDown
    lw  $t1, left
    beq $t0, $t1, moveTailLeft
    lw  $t1, right
    beq $t0, $t1, moveTailRight
    j   drawHead                # If no direction match, just draw head

moveTailUp:
    add $s2, $s2, -256
    j   drawHead
moveTailDown:
    add $s2, $s2, 256
    j   drawHead
moveTailLeft:
    add $s2, $s2, -4
    j   drawHead
moveTailRight:
    add $s2, $s2, 4
    j   drawHead

### DRAW HEAD 
drawHead:
    lw  $t0, snakecolor     # load snake color
    sw  $t0, 0($s1)         # load color to head square
    j   gameLoop

##################### FOOD FUNCTION ########################
foodEvent:
    add $s0, $s0, 1             # increment score by 1
    li  $s5, 1                  # set food eaten flag to true (1)
    jal randomFoodLocation      # draw new food
    j   drawHead                # back to update snake
                                # on food event we don't delete tail

randomFoodLocation:
    # Save return address
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # Generate the location of apple
    li  $v0, 42
    li  $a0, 0                # Random generator ID = 0
    li  $a1, 2047             # upperbound = 2047
    syscall                   # a0 = rand[0, 2047]

    # Check if location is valid
    la  $t0, squares          # base address
    sll $a0, $a0, 2           # a0 = a0 * 4
    add $t0, $t0, $a0         # address of the randomized square

    lw  $t1, 0($t0)                     # load randomized square's color
    lw  $t2, bgcolor                    # load bg color
    bne $t1, $t2, randomFoodLocation    # rerandom if square's color != bg color
                                        # (square is occupied)

drawFood:
    lw  $t1, foodcolor      # load food color
    sw  $t1, 0($t0)         # to the randomized square
    
    # Restore return address
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr  $ra

##################### GAME FUNCTION ########################
gameLoop:
    # Auto-running snake - brief pause between moves
    li $v0, 32                  # syscall code for sleep
    li $a0, 200                 # sleep for 200ms (adjust for desired speed)
    syscall
    
    # Check for keyboard input
    li $v0, 12                  # syscall code for read character
    li $a1, 0                   # non-blocking mode (check and continue)
    syscall                     # Returns character in $v0 or 0 if no input
    
    # If a key was pressed, process it
    beqz $v0, checkAutoMove     # If $v0 = 0, no key was pressed
    sw $v0, lastInput           # Store the input
    j processInput              # Process the input
    
checkAutoMove:
    # Always move in current direction if direction is set
    bnez $s3, updateHead        # If direction != 0, update head position
    j gameLoop                  # Otherwise, keep checking for input
    
checkConnectionLost:
    # In a real implementation, we'd check the connection status
    # For now we just handle the case with a message
    li $v0, 4
    la $a0, connectionLostMsg
    syscall
    
    li $s4, 1                   # Set disconnection flag
    j exitProgram               # Exit the program
    
processInput:
    lw $t0, lastInput           # get the stored input
    sw $zero, lastInput         # reset input after processing
    
    # Convert to lowercase if uppercase
    blt $t0, 65, skipToCheck    # If < 'A', skip
    bgt $t0, 90, skipToCheck    # If > 'Z', skip
    addi $t0, $t0, 32           # Convert to lowercase (A->a, etc.)
    
skipToCheck:
    beq $t0, 119, changeUp      # input character == 'w'
    beq $t0, 115, changeDown    # input character == 's'
    beq $t0, 97, changeLeft     # input character == 'a'
    beq $t0, 100, changeRight   # input character == 'd'
    beq $t0, 113, userQuit      # input character == 'q' (QUIT)

    # If no recognized key pressed, continue with automatic movement
    j checkAutoMove             # Continue with auto movement

userQuit:
    # User pressed 'q' to quit
    li $v0, 4
    la $a0, quitMsg
    syscall
    j exitProgram

changeUp:
    lw  $t1, down               # the snake is not allowed to change direction
    beq $s3, $t1, checkAutoMove # to <Up> when it's moving <Down>   

    lw  $s3, up                 # change direction
    j   checkAutoMove           # continue with game loop
    
changeDown:
    lw  $t1, up                 # the snake is not allowed to change direction
    beq $s3, $t1, checkAutoMove # to <Down> when it's moving <Up>

    lw  $s3, down               # change direction
    j   checkAutoMove           # continue with game loop
    
changeLeft:
    lw  $t1, right              # the snake is not allowed to change direction
    beq $s3, $t1, checkAutoMove # to <Left> when it's moving <Right>

    lw  $s3, left               # change direction
    j   checkAutoMove           # continue with game loop
    
changeRight:
    lw  $t1, left               # the snake is not allowed to change direction
    beq $s3, $t1, checkAutoMove # to <Right> when it's moving <Left>

    lw  $s3, right              # change direction
    j   checkAutoMove           # continue with game loop
    
gameOver:
    # Print game over and players' score message
    li  $v0, 4
    la  $a0, gameOverStr
    syscall
    li  $v0, 1
    add $a0, $s0, $zero         # score is at $s0
    syscall
    li  $v0, 4
    la  $a0, endline
    syscall

    # Ask player if they want to play again
    li  $v0, 50
    la  $a0, askPlayer
    syscall
    
    beqz $a0, begin             # if yes = player chooses to play again
    j    exitProgram            # else terminate program

##################### EXIT HANDLING ########################
exitProgram:
    # Check why we're exiting
    beqz $s4, normalExit        # If connection status is 0, normal exit
    
    # Connection lost exit
    li $v0, 4
    la $a0, connectionLostMsg
    syscall
    
normalExit:
    # Clean termination of the program
    li $v0, 10                  # syscall code for exit
    syscall