# Enhanced Electric Guitar Simulator with Proper Chord Detection
.data
    welcome_msg:    .asciiz "Enhanced Electric Guitar Simulator\n"
    instructions:   .asciiz "\nPlay single notes or chords:\n"
    single_notes:   .asciiz "Single notes: z=G, x=A, c=B, v=C, b=D, n=E, m=F\n"
    chord_guide:    .asciiz "Chords: asd=G, fgh=C, jkl=D, qwe=Em, rty=Am, uio=F\n"
                   .asciiz "Press 'p' to quit\n"
    playing:        .asciiz "\nPlaying: "
    g_chord:        .asciiz "G major chord\n"
    c_chord:        .asciiz "C major chord\n"
    d_chord:        .asciiz "D major chord\n"
    em_chord:       .asciiz "E minor chord\n"
    am_chord:       .asciiz "A minor chord\n"
    f_chord:        .asciiz "F major chord\n"
    quit_msg:       .asciiz "\nExiting Guitar Simulator...\n"
    
    # MIDI notes for single notes (G3-F4)
    single_note_pitches: .word 67, 69, 71, 72, 74, 76, 77  # G3 to F4
    single_note_names: .asciiz "G", "A", "B", "C", "D", "E", "F"
    
    # MIDI notes for chords
    g_notes:        .word 67, 71, 74  # G, B, D
    c_notes:        .word 60, 64, 67  # C, E, G
    d_notes:        .word 62, 66, 69  # D, F#, A
    em_notes:       .word 64, 67, 71  # E, G, B
    am_notes:       .word 69, 72, 76  # A, C, E
    f_notes:        .word 65, 69, 72  # F, A, C
    
    # Key mappings
    single_keys:    .byte 'z', 'x', 'c', 'v', 'b', 'n', 'm'  # Changed from a-l
    chord_patterns:  .asciiz "asd", "fgh", "jkl", "qwe", "rty", "uio"
    chord_messages:  .word g_chord, c_chord, d_chord, em_chord, am_chord, f_chord
    chord_notes:    .word g_notes, c_notes, d_notes, em_notes, am_notes, f_notes
    
    # Buffer for key sequence
    buffer:         .space 4
    buffer_index:   .word 0
    
    # Duration and instrument settings
    note_duration:  .word 500     # Duration for single notes
    chord_duration: .word 1000    # Duration for chords
    instrument:     .word 30      # Distortion guitar
    volume:         .word 100

.text
.globl main

main:
    # Print welcome and instructions
    li $v0, 4
    la $a0, welcome_msg
    syscall
    la $a0, instructions
    syscall
    la $a0, single_notes
    syscall
    la $a0, chord_guide
    syscall

input_loop:
    # Read character from keyboard
    li $v0, 12
    syscall
    
    # Check for quit command
    beq $v0, 'p', exit_program
    
    # Store character in buffer
    la $t0, buffer
    lw $t1, buffer_index
    add $t0, $t0, $t1
    sb $v0, 0($t0)
    
    # Increment buffer index
    addi $t1, $t1, 1
    sw $t1, buffer_index
    
    # Check if we should process as chord (3 keys)
    li $t2, 3
    bne $t1, $t2, check_single_note
    
process_chord:
    # Check chord patterns
    la $s0, chord_patterns    # Patterns to check against
    la $s1, chord_messages    # Corresponding messages
    la $s2, chord_notes       # Corresponding notes
    li $s3, 0                 # Pattern counter
    li $s4, 6                 # Number of patterns
    
check_chord_patterns:
    # Load current pattern
    add $t0, $s0, $s3
    add $t0, $t0, $s3
    add $t0, $t0, $s3         # 3 bytes per pattern
    
    # Compare with buffer
    la $t1, buffer
    lb $t2, 0($t0)            # First char of pattern
    lb $t3, 0($t1)            # First char of buffer
    bne $t2, $t3, next_pattern
    
    lb $t2, 1($t0)            # Second char
    lb $t3, 1($t1)            # Second char
    bne $t2, $t3, next_pattern
    
    lb $t2, 2($t0)            # Third char
    lb $t3, 2($t1)            # Third char
    bne $t2, $t3, next_pattern
    
    # Pattern matches - play chord
    li $v0, 4
    la $a0, playing
    syscall
    
    # Print chord name
    sll $t4, $s3, 2
    add $t5, $s1, $t4
    lw $a0, 0($t5)
    syscall
    
    # Play chord
    add $t5, $s2, $t4
    lw $t9, 0($t5)
    jal play_chord
    j reset_buffer
    
next_pattern:
    addi $s3, $s3, 1
    blt $s3, $s4, check_chord_patterns
    
    # No matching pattern found - treat as single notes
    j play_buffer_as_single_notes

check_single_note:
    # Check if single note (only after checking for chords fails)
    la $t0, single_keys
    li $t1, 0
check_single_loop:
    lb $t2, 0($t0)
    beq $v0, $t2, play_single_note
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    blt $t1, 7, check_single_loop
    
    # Not a valid single note or part of chord
    j invalid_sequence

play_buffer_as_single_notes:
    # Play each key in buffer as single note
    la $t0, buffer
    li $t1, 0
play_single_notes_loop:
    lb $t2, 0($t0)
    beqz $t2, reset_buffer  # End of buffer
    
    # Find which single note this is
    la $t3, single_keys
    li $t4, 0
find_note_index:
    lb $t5, 0($t3)
    beq $t2, $t5, play_found_note
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    blt $t4, 7, find_note_index
    j next_single_note  # Not a single note
    
play_found_note:
    # Play the single note
    sll $t6, $t4, 2
    la $t7, single_note_pitches
    add $t7, $t7, $t6
    lw $a0, 0($t7)
    
    li $v0, 4
    la $a0, playing
    syscall
    
    # Print note name
    la $t8, single_note_names
    add $t8, $t8, $t4
    lb $a0, 0($t8)
    li $v0, 11
    syscall
    li $a0, '\n'
    syscall
    
    # Play the note
    lw $a0, 0($t7)
    li $v0, 33
    lw $a1, note_duration
    lw $a2, instrument
    lw $a3, volume
    syscall
    
    # Small delay between notes
    li $a0, 100
    li $v0, 32
    syscall
    
next_single_note:
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    blt $t1, 3, play_single_notes_loop
    j reset_buffer

play_single_note:
    # Play immediately detected single note
    sll $t3, $t1, 2
    la $t4, single_note_pitches
    add $t4, $t4, $t3
    lw $a0, 0($t4)
    
    li $v0, 4
    la $a0, playing
    syscall
    
    # Print note name
    la $t5, single_note_names
    add $t5, $t5, $t1
    lb $a0, 0($t5)
    li $v0, 11
    syscall
    li $a0, '\n'
    syscall
    
    # Play the note
    lw $a0, 0($t4)
    li $v0, 33
    lw $a1, note_duration
    lw $a2, instrument
    lw $a3, volume
    syscall
    
    # Don't reset buffer here - wait to see if it's part of a chord
    j input_loop

invalid_sequence:
    # Invalid sequence - play error sound
    li $v0, 33
    li $a0, 60        # Middle C
    li $a1, 200       # Short duration
    li $a2, 118       # Synth drum
    li $a3, 70        # Volume
    syscall
    
reset_buffer:
    # Clear buffer
    sw $zero, buffer_index
    j input_loop

play_chord:
    # Play a 3-note chord (address in $t9)
    move $s5, $ra     # Save return address
    
    # Play first note
    lw $a0, 0($t9)
    li $v0, 33
    lw $a1, chord_duration
    lw $a2, instrument
    lw $a3, volume
    syscall
    
    # Small delay
    li $a0, 50
    li $v0, 32
    syscall
    
    # Play second note
    lw $a0, 4($t9)
    li $v0, 33
    lw $a1, chord_duration
    lw $a2, instrument
    lw $a3, volume
    syscall
    
    # Small delay
    li $a0, 50
    li $v0, 32
    syscall
    
    # Play third note
    lw $a0, 8($t9)
    li $v0, 33
    lw $a1, chord_duration
    lw $a2, instrument
    lw $a3, volume
    syscall
    
    move $ra, $s5     # Restore return address
    jr $ra

exit_program:
    # Print exit message
    li $v0, 4
    la $a0, quit_msg
    syscall
    
    # Exit program
    li $v0, 10
    syscall