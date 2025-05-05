.data
### BITMAP SETTINGS
### Unit Width in pixels: 8
### Unit Height in pixels: 8  
### Display Width in pixels: 512 -> 64 squares/row
### Display Height in pixels: 256 -> 32 squares/column

# Guitar strings configuration
display_address: .word 0x00000000   # Starting at 0x00000000
background_color: .word 0x5E4D37    # Brown wooden color for guitar body
string_relaxed:   .word 0xD3D3D3    # Light gray for relaxed strings
string_vibrating: .word 0xFFFFFF    # White for vibrating strings
string_plucked:   .word 0x00FF00    # Green for plucked position

# Guitar string positions (Y coordinates)
string1_pos: .word 4       # High E string
string2_pos: .word 8       # B string
string3_pos: .word 12      # G string
string4_pos: .word 16      # D string
string5_pos: .word 20      # A string
string6_pos: .word 24      # Low E string

# Guitar string frequencies (in Hz)
string1_freq: .word 330    # High E string (E4 = 329.63 Hz)
string2_freq: .word 247    # B string (B3 = 246.94 Hz)
string3_freq: .word 196    # G string (G3 = 196.00 Hz)
string4_freq: .word 147    # D string (D3 = 146.83 Hz)
string5_freq: .word 110    # A string (A2 = 110.00 Hz)
string6_freq: .word 82     # Low E string (E2 = 82.41 Hz)

# Sound parameters
sound_duration: .word 500   # Sound duration in ms
sound_instrument: .word 24  # Acoustic Guitar (nylon) MIDI instrument

# Messages
welcome_msg:       .asciiz "Guitar Simulator\n"
instructions_msg:  .asciiz "Press keys 1-6 to play strings\nPress 'q' to quit\n"
pluck1_msg:        .asciiz "String 1 (High E) plucked!\n"
pluck2_msg:        .asciiz "String 2 (B) plucked!\n"
pluck3_msg:        .asciiz "String 3 (G) plucked!\n"
pluck4_msg:        .asciiz "String 4 (D) plucked!\n"
pluck5_msg:        .asciiz "String 5 (A) plucked!\n"
pluck6_msg:        .asciiz "String 6 (Low E) plucked!\n"
exit_msg:          .asciiz "Thanks for playing!\n"
ready_msg:         .asciiz "Ready for next key...\n"

# Animation control
vibration_time:    .word 50    # Vibration duration in ms (reduced for better responsiveness)
vibration_states:  .space 24   # 6 strings x 4 bytes to track vibration state

# Thread control
string_threads:    .space 24   # 6 strings x 4 bytes to store thread IDs

.text
.globl main

main:
    # Display welcome message
    li $v0, 4
    la $a0, welcome_msg
    syscall
    
    # Display instructions
    li $v0, 4
    la $a0, instructions_msg
    syscall
    
    # Initialize guitar display
    jal draw_guitar_body
    jal draw_all_strings
    
    # Initialize vibration states to 0
    la $t0, vibration_states
    li $t1, 0
    sw $t1, 0($t0)   # String 1
    sw $t1, 4($t0)   # String 2 
    sw $t1, 8($t0)   # String 3
    sw $t1, 12($t0)  # String 4
    sw $t1, 16($t0)  # String 5
    sw $t1, 20($t0)  # String 6
    
    # Main loop
guitar_loop:
    # Show ready message
    li $v0, 4
    la $a0, ready_msg
    syscall
    
    # Read keyboard input (non-blocking would be better but using what's available)
    li $v0, 12       # Read character
    syscall
    move $t0, $v0    # Save input character in $t0
    
    # Check if quit
    li $t1, 'q'
    beq $t0, $t1, exit_program
    
    # Check which string to pluck
    li $t1, '1'
    beq $t0, $t1, pluck_string1
    
    li $t1, '2'
    beq $t0, $t1, pluck_string2
    
    li $t1, '3'
    beq $t0, $t1, pluck_string3
    
    li $t1, '4'
    beq $t0, $t1, pluck_string4
    
    li $t1, '5'
    beq $t0, $t1, pluck_string5
    
    li $t1, '6'
    beq $t0, $t1, pluck_string6
    
    # If no valid key, continue loop
    j guitar_loop
    
pluck_string1:
    # Print message
    li $v0, 4
    la $a0, pluck1_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 0($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 0($t0)
    
    # Play sound
    lw $a0, string1_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string1_pos
    li $a1, 1                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
pluck_string2:
    # Print message
    li $v0, 4
    la $a0, pluck2_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 4($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 4($t0)
    
    # Play sound
    lw $a0, string2_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string2_pos
    li $a1, 2                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
pluck_string3:
    # Print message
    li $v0, 4
    la $a0, pluck3_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 8($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 8($t0)
    
    # Play sound
    lw $a0, string3_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string3_pos
    li $a1, 3                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
pluck_string4:
    # Print message
    li $v0, 4
    la $a0, pluck4_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 12($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 12($t0)
    
    # Play sound
    lw $a0, string4_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string4_pos
    li $a1, 4                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
pluck_string5:
    # Print message
    li $v0, 4
    la $a0, pluck5_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 16($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 16($t0)
    
    # Play sound
    lw $a0, string5_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string5_pos
    li $a1, 5                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
pluck_string6:
    # Print message
    li $v0, 4
    la $a0, pluck6_msg
    syscall
    
    # Check if string is already vibrating
    la $t0, vibration_states
    lw $t1, 20($t0)
    bnez $t1, guitar_loop    # Skip if already vibrating
    
    # Set vibration state to active
    li $t1, 1
    sw $t1, 20($t0)
    
    # Play sound
    lw $a0, string6_freq
    jal play_sound
    
    # Pluck the string (without blocking)
    lw $a0, string6_pos
    li $a1, 6                # String ID for thread
    jal start_pluck_thread
    
    # Continue main loop immediately
    j guitar_loop
    
exit_program:
    # Display exit message
    li $v0, 4
    la $a0, exit_msg
    syscall
    
    # Exit program
    li $v0, 10
    syscall

# Start a new thread for string plucking animation
# $a0 = Y position of string
# $a1 = String number (1-6)
start_pluck_thread:
    # Save return address
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a1, 4($sp)
    
    # Save string position and ID
    move $s0, $a0    # String Y position
    move $s1, $a1    # String ID
    
    # Now call pluck_string directly (in a real system with threads available,
    # we would start a thread here instead)
    jal pluck_string
    
    # Restore return address
    lw $ra, 0($sp)
    lw $a1, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Play sound for a given frequency in $a0
play_sound:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Configure MIDI note
    move $a1, $a0           # Frequency in Hz
    lw $a2, sound_duration  # Duration
    lw $a3, sound_instrument # Instrument (24 = Acoustic Guitar)
    
    # Use MIDI syscall (31) to play sound
    # $a0 = pitch (we're using our frequency directly)
    # $a1 = duration in ms
    # $a2 = instrument
    # $a3 = volume (0-127)
    li $v0, 31              # MIDI syscall
    move $a0, $a1           # Move frequency to $a0
    move $a1, $a2           # Duration
    move $a2, $a3           # Instrument
    li $a3, 100             # Volume (0-127)
    syscall
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw the guitar body (background)
draw_guitar_body:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, display_address  # Base address (0x00000000)
    lw $t1, background_color # Color
    li $t2, 0                # Counter
    li $t3, 8192             # Total bytes (64x32x4)
    
body_loop:
    # Check if we've reached the end of available memory
    # For safety, we'll limit to 8KB (8192 bytes)
    bge $t2, $t3, body_done
    
    sw $t1, 0($t0)           # Draw pixel
    addi $t0, $t0, 4         # Move to next pixel
    addi $t2, $t2, 4         # Increment counter (by bytes)
    j body_loop
    
body_done:
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw all guitar strings in relaxed state
draw_all_strings:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Draw string 1 (High E)
    lw $a0, string1_pos
    jal draw_relaxed_string
    
    # Draw string 2 (B)
    lw $a0, string2_pos
    jal draw_relaxed_string
    
    # Draw string 3 (G)
    lw $a0, string3_pos
    jal draw_relaxed_string
    
    # Draw string 4 (D)
    lw $a0, string4_pos
    jal draw_relaxed_string
    
    # Draw string 5 (A)
    lw $a0, string5_pos
    jal draw_relaxed_string
    
    # Draw string 6 (Low E)
    lw $a0, string6_pos
    jal draw_relaxed_string
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Draw a single relaxed string at Y position in $a0
draw_relaxed_string:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, display_address  # Base address
    lw $t1, string_relaxed   # String color
    li $t2, 64               # String length (full width)
    
    # Calculate starting address for string
    # Each row is 64 pixels * 4 bytes = 256 bytes
    mul $t3, $a0, 256        # y * 256 (row offset)
    add $t0, $t0, $t3        # Add to base
    
    # Draw the string
string_pixel_loop:
    # Check if address is within bounds
    bge $t0, 0x00002000, string_done  # Don't go beyond 8KB
    
    sw $t1, 0($t0)           # Draw pixel
    addi $t0, $t0, 4         # Move to next pixel
    addi $t2, $t2, -1        # Decrement counter
    bgtz $t2, string_pixel_loop # Continue if not done
    
string_done:
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Pluck a string at Y position in $a0
pluck_string:
    # Save return address and registers
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    move $s0, $a0            # Save Y position
    
    # Show plucked point (middle of string)
    lw $t0, display_address  # Base address
    lw $t1, string_plucked   # Plucked color
    
    # Calculate address for middle of string
    mul $t2, $s0, 256        # y * 256 (row offset)
    add $t0, $t0, $t2        # Base + row offset
    addi $t0, $t0, 128       # + middle offset (32*4)
    
    # Check if address is valid
    blt $t0, 0x00002000, draw_pluck  # Only draw if within bounds
    j skip_pluck
    
draw_pluck:
    sw $t1, 0($t0)           # Draw plucked point
    
skip_pluck:
    # Animate vibrating string
    li $s1, 3                # Number of vibration cycles
    
vibration_loop:
    # Draw vibrating string
    move $a0, $s0
    jal draw_vibrating_string
    
    # Sleep 
    li $v0, 32
    lw $a0, vibration_time
    syscall
    
    # Draw relaxed string
    move $a0, $s0
    jal draw_relaxed_string
    
    # Sleep 
    li $v0, 32
    lw $a0, vibration_time
    syscall
    
    # Decrement cycle counter
    addi $s1, $s1, -1
    bgtz $s1, vibration_loop
    
    # Reset vibration state
    la $t0, vibration_states
    
    # Find correct offset based on string position
    lw $t1, string1_pos
    beq $s0, $t1, reset_string1
    
    lw $t1, string2_pos
    beq $s0, $t1, reset_string2
    
    lw $t1, string3_pos
    beq $s0, $t1, reset_string3
    
    lw $t1, string4_pos
    beq $s0, $t1, reset_string4
    
    lw $t1, string5_pos
    beq $s0, $t1, reset_string5
    
    j reset_string6  # Must be string 6
    
reset_string1:
    sw $zero, 0($t0)
    j reset_done
    
reset_string2:
    sw $zero, 4($t0)
    j reset_done
    
reset_string3:
    sw $zero, 8($t0)
    j reset_done
    
reset_string4:
    sw $zero, 12($t0)
    j reset_done
    
reset_string5:
    sw $zero, 16($t0)
    j reset_done
    
reset_string6:
    sw $zero, 20($t0)
    
reset_done:
    # Restore return address and registers
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# Draw a vibrating string at Y position in $a0
draw_vibrating_string:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, display_address  # Base address
    lw $t1, string_vibrating # String color
    li $t2, 64               # String length (full width)
    
    # Store original y-position
    move $t4, $a0
    
    # Draw the string with wave pattern
    li $t5, 0               # X position counter
    
vibrate_loop:
    # Calculate wave pattern - use sine-like pattern
    rem $t6, $t5, 6         # t6 = x % 6
    
    # Default y offset is 0
    li $t7, 0
    
    # Apply different offsets based on position
    beq $t6, 1, pos_offset
    beq $t6, 4, pos_offset
    beq $t6, 2, neg_offset
    beq $t6, 5, neg_offset
    j draw_pixel
    
pos_offset:
    li $t7, 1
    j draw_pixel
    
neg_offset:
    li $t7, -1
    
draw_pixel:
    # Calculate pixel address
    lw $t0, display_address
    
    # Calculate y position with offset
    add $t8, $t4, $t7       # y + offset
    
    # Calculate address: (y * 64 + x) * 4
    mul $t9, $t8, 256        # y * 64 * 4
    mul $t3, $t5, 4          # x * 4
    add $t9, $t9, $t3        # (y*64 + x)*4
    add $t0, $t0, $t9        # base + offset
    
    # Check if address is valid
    blt $t0, 0x00002000, safe_draw  # Only draw if within bounds
    j skip_draw
    
safe_draw:
    sw $t1, 0($t0)
    
skip_draw:
    # Increment and check
    addi $t5, $t5, 1
    blt $t5, $t2, vibrate_loop
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra