.data
    # Memory allocation for the game grid
    squares:        .space  8192           # 2048 squares x 4 bytes = 8192 bytes
                                           # Direction code (2 high bytes) + color code (6 low bytes)
    # Colors
    bgcolor:        .word   0xcefad0        # light green
    wallcolor:      .word   0x008631        # dark green
    snakecolor:     .word   0x0000ff        # blue
    foodcolor:      .word   0xff0000        # red
    
    # Direction codes
    up:             .word   0x01000000
    down:           .word   0x02000000
    left:           .word   0x03000000
    right:          .word   0x04000000
    
    # Game messages
    gameOverStr:    .asciiz "Game over! Your score: "
    endline:        .asciiz "\n"
    askPlayer:      .asciiz "\nDo you want to play again?"
    startMsg:       .asciiz "\nSnake Game Started! Use w/a/s/d to change direction.\n"
    quitMsg:        .asciiz "\nQuitting game... Thanks for playing!\n"
    
    # Keyboard input variable
    lastInput:      .word   0
    
.text

####################### INIT GAME #######################
begin:
    li  $s0, 0              # reset score
    li  $s5, 0              # reset food eaten flag
    lw  $s3, right          # set initial direction to right
    sw  $zero, lastInput    # reset user input

####################### DRAW BACKGROUND #######################
    la  $t0, squares        # load base address
    li  $t1, 2048           # number of squares
    lw  $t2, bgcolor        # load background color
loop1:
    sw  $t2, 0($t0)         # fill square with background color
    add $t0, $t0, 4         # next square address
    addi $t1, $t1, -1       # decrement counter
    bnez $t1, loop1         # continue until all squares filled

####################### DRAW WALLS #######################
    # Top wall
    la  $t0, squares
    li  $t1, 64             # 64 squares in top row
    lw  $t2, wallcolor
drawTopWall:
    sw  $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, drawTopWall

    # Bottom wall
    la  $t0, squares
    addi $t0, $t0, 7936     # Move to bottom row (31*256)
    li  $t1, 64
drawBottomWall:
    sw  $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, drawBottomWall

    # Left wall
    la  $t0, squares
    addi $t0, $t0, 256      # Move to second row
    li  $t1, 30             # 30 squares in column (excluding corners)
drawLeftWall:
    sw  $t2, 0($t0)
    addi $t0, $t0, 256      # Move down one row
    addi $t1, $t1, -1
    bnez $t1, drawLeftWall

    # Right wall
    la  $t0, squares
    addi $t0, $t0, 508      # Last column, second row
    li  $t1, 30
drawRightWall:
    sw  $t2, 0($t0)
    addi $t0, $t0, 256
    addi $t1, $t1, -1
    bnez $t1, drawRightWall

####################### INIT SNAKE #######################
    la  $t0, squares
    addi $t0, $t0, 3964     # Middle of screen
    move $s1, $t0           # Set head address
    lw  $t1, snakecolor
    sw  $t1, 0($t0)         # Draw head
    
    lw  $t2, right
    or  $t1, $t1, $t2       # Combine color and direction
    sw  $t1, -4($t0)        # Draw middle segment
    sw  $t1, -8($t0)        # Draw tail segment
    
    addi $t0, $t0, -8       # Set tail address
    move $s2, $t0

####################### INITIAL FOOD #######################
    jal randomFoodLocation

####################### START GAME #######################
    # Display start message
    li $v0, 4
    la $a0, startMsg
    syscall
    
    j gameLoop

####################### UPDATE HEAD #######################
updateHead:
    # Set direction in current head square
    lw  $t0, 0($s1)
    li  $t1, 0x00ffffff     # Mask to preserve color
    and $t0, $t0, $t1       # Clear direction bits
    or  $t0, $t0, $s3       # Add direction
    sw  $t0, 0($s1)
    
    # Update head position based on direction
    lw  $t0, up
    beq $s3, $t0, moveHeadUp
    lw  $t0, down
    beq $s3, $t0, moveHeadDown
    lw  $t0, left
    beq $s3, $t0, moveHeadLeft
    # Must be right if none of the above
    addi $s1, $s1, 4        # Move right
    j checkCollision

moveHeadUp:
    addi $s1, $s1, -256
    j checkCollision
moveHeadDown:
    addi $s1, $s1, 256
    j checkCollision
moveHeadLeft:
    addi $s1, $s1, -4
    j checkCollision
moveHeadRight:             # This label is unnecessary but kept for clarity
    addi $s1, $s1, 4
    # Fall through to checkCollision

####################### COLLISION DETECTION #######################
checkCollision:
    lw  $t0, 0($s1)         # Get color at new head position
    lw  $t1, foodcolor
    beq $t0, $t1, foodEvent # Food collision
    lw  $t1, bgcolor
    beq $t0, $t1, cont      # Empty space, continue
    
    j gameOver              # Wall or self collision

####################### UPDATE TAIL #######################
cont:
    li  $s5, 0              # Reset food eaten flag
    
    lw  $t0, 0($s2)         # Get tail direction
    li  $t1, 0xff000000
    and $t0, $t0, $t1       # Extract direction
    
    # Clear old tail
    lw  $t1, bgcolor
    sw  $t1, 0($s2)
    
    # Update tail position based on direction
    lw  $t1, up
    beq $t0, $t1, moveTailUp
    lw  $t1, down
    beq $t0, $t1, moveTailDown
    lw  $t1, left
    beq $t0, $t1, moveTailLeft
    # Must be right if none of the above
    addi $s2, $s2, 4
    j drawHead

moveTailUp:
    addi $s2, $s2, -256
    j drawHead
moveTailDown:
    addi $s2, $s2, 256
    j drawHead
moveTailLeft:
    addi $s2, $s2, -4
    j drawHead

####################### DRAW HEAD #######################
drawHead:
    lw  $t0, snakecolor
    sw  $t0, 0($s1)
    j gameLoop

####################### FOOD HANDLING #######################
foodEvent:
    addi $s0, $s0, 1        # Increment score
    li  $s5, 1              # Set food eaten flag
    jal randomFoodLocation
    j drawHead              # Don't delete tail when food is eaten

randomFoodLocation:
    # Save return address
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # Generate random location
    li  $v0, 42
    li  $a0, 0
    li  $a1, 2047
    syscall
    
    # Check if location is valid
    la  $t0, squares
    sll $a0, $a0, 2         # Multiply by 4 for byte address
    add $t0, $t0, $a0
    
    lw  $t1, 0($t0)
    lw  $t2, bgcolor
    bne $t1, $t2, randomFoodLocation  # Try again if not empty
    
    # Draw food
    lw  $t1, foodcolor
    sw  $t1, 0($t0)
    
    # Restore return address
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr  $ra

####################### GAME LOOP #######################
gameLoop:
    # Brief pause between moves
    li $v0, 32
    li $a0, 200             # 200ms delay
    syscall
    
    # Check for keyboard input
    li $v0, 12
    li $a1, 0               # Non-blocking mode
    syscall
    
    beqz $v0, checkAutoMove # No key pressed
    sw $v0, lastInput       # Store input
    
processInput:
    lw $t0, lastInput
    sw $zero, lastInput     # Reset input
    
    # Convert to lowercase if needed
    blt $t0, 65, skipToCheck
    bgt $t0, 90, skipToCheck
    addi $t0, $t0, 32       # A->a, etc.
    
skipToCheck:
    beq $t0, 119, changeUp      # w
    beq $t0, 115, changeDown    # s
    beq $t0, 97, changeLeft     # a
    beq $t0, 100, changeRight   # d
    beq $t0, 113, userQuit      # q
    
checkAutoMove:
    bnez $s3, updateHead    # Continue in current direction
    j gameLoop

userQuit:
    li $v0, 4
    la $a0, quitMsg
    syscall
    j exitProgram

changeUp:
    lw  $t1, down
    beq $s3, $t1, checkAutoMove  # Can't go up if moving down
    lw  $s3, up
    j checkAutoMove
    
changeDown:
    lw  $t1, up
    beq $s3, $t1, checkAutoMove  # Can't go down if moving up
    lw  $s3, down
    j checkAutoMove
    
changeLeft:
    lw  $t1, right
    beq $s3, $t1, checkAutoMove  # Can't go left if moving right
    lw  $s3, left
    j checkAutoMove
    
changeRight:
    lw  $t1, left
    beq $s3, $t1, checkAutoMove  # Can't go right if moving left
    lw  $s3, right
    j checkAutoMove

####################### GAME OVER #######################
gameOver:
    # Show game over and score
    li  $v0, 4
    la  $a0, gameOverStr
    syscall
    li  $v0, 1
    move $a0, $s0
    syscall
    li  $v0, 4
    la  $a0, endline
    syscall
    
    # Ask to play again
    li  $v0, 50
    la  $a0, askPlayer
    syscall
    
    beqz $a0, begin      # Yes - play again
    # Fall through to exit
    
####################### EXIT #######################
exitProgram:
    li $v0, 10          # Exit program
    syscall