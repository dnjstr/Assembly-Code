.data
    welcome_msg:    .asciiz "Virtual Guitar Simulator\nPress keys a-s-d-f-g-h-j-k-l to play strings\nPress 'q' to quit\n"
    quit_msg:       .asciiz "\nExiting Virtual Guitar...\n"
    
    # MIDI pitch values for guitar strings (E2, A2, D3, G3, B3, E4)
    string_pitches: .word 64, 69, 74, 79, 83, 88
    string_names:    .asciiz "E2", "A2", "D3", "G3", "B3", "E4"
    
    # Key to string mapping (a-s-d-f-g-h-j-k-l)
    key_map:        .byte 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'
    
    # Duration of each note in milliseconds
    duration:       .word 500
    
    # MIDI instrument 24 is acoustic guitar (nylon)
    instrument:     .word 24
    
    # Volume (0-127)
    volume:         .word 100

.text
.globl main

main:
    # Print welcome message
    li $v0, 4
    la $a0, welcome_msg
    syscall
    
    # Set instrument
    li $v0, 33
    lw $a0, instrument
    li $a1, 0
    li $a2, 0
    li $a3, 127
    syscall
    
input_loop:
    # Read character from keyboard
    li $v0, 12
    syscall
    
    # Check for quit command ('q')
    beq $v0, 'q', exit_program
    
    # Check which key was pressed
    la $t0, key_map
    li $t1, 0               # index counter
    
check_key:
    lb $t2, 0($t0)          # load key from map
    beq $v0, $t2, play_note # if key matches, play note
    
    addi $t0, $t0, 1        # move to next key in map
    addi $t1, $t1, 1        # increment index
    
    blt $t1, 9, check_key   # if not all keys checked, continue
    j input_loop            # key not found, get next input
    
play_note:
    # Bound the index to our string pitches (0-5)
    rem $t1, $t1, 6
    
    # Calculate address of pitch to play
    sll $t3, $t1, 2         # multiply index by 4 (word size)
    la $t4, string_pitches
    add $t4, $t4, $t3
    lw $a0, 0($t4)          # load pitch value
    
    # Print which string is being played
    la $t5, string_names
    mul $t6, $t1, 3         # each string name is 3 bytes
    add $t5, $t5, $t6
    
    li $v0, 4
    move $a0, $t5
    syscall
    
    li $v0, 11
    li $a0, '\n'
    syscall
    
    # Play the note
    li $v0, 33              # MIDI out synchronous
    lw $a0, ($t4)           # pitch
    lw $a1, duration        # duration
    lw $a2, instrument      # instrument
    lw $a3, volume          # volume
    syscall
    
    j input_loop
    
exit_program:
    # Print exit message
    li $v0, 4
    la $a0, quit_msg
    syscall
    
    # Exit program
    li $v0, 10
    syscall
