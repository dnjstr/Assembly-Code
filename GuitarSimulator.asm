.data
    welcome_msg:    .asciiz "Virtual Guitar Simulator\n\nIndividual Notes:\n- Press keys a-s-d-f-g-h to play open strings (E2, A2, D3, G3, B3, E4)\n- Press 1-9 to play frets on the current string\n\nChord Mode:\n- Press z-x-c-v-b-n to play and toggle strings for chord\n- Press SPACE to strum all selected strings\n\nPress 'q' to quit\n"
    quit_msg:       .asciiz "\nExiting Virtual Guitar...\n"
    string_played:  .asciiz "Playing string: "
    fret_played:    .asciiz " fret: "
    chord_msg:      .asciiz "Playing chord\n"
    newline:        .asciiz "\n"
    
    # For chord playing - which strings are being played (0=not played, 1=played)
    chord_strings:  .word 0, 0, 0, 0, 0, 0
    
    # Standard guitar tuning (E2, A2, D3, G3, B3, E4) - Correct MIDI values
    string_pitches: .word 40, 45, 50, 55, 59, 64
    string_names:   .asciiz "E2", "A2", "D3", "G3", "B3", "E4"
    
    # Key to string mapping (a-s-d-f-g-h)
    key_map:        .byte 'a', 's', 'd', 'f', 'g', 'h'
    
    # Chord key to string mapping (z-x-c-v-b-n)
    chord_key_map:  .byte 'z', 'x', 'c', 'v', 'b', 'n'
    
    # Duration of each note in milliseconds
    duration:       .word 500
    
    # MIDI instrument values:
    # 24: Acoustic Guitar (nylon)
    # 25: Acoustic Guitar (steel)
    # 26: Electric Guitar (jazz)
    # 27: Electric Guitar (clean)
    # 28: Electric Guitar (muted)
    # 29: Overdriven Guitar
    # 30: Distortion Guitar
    instrument:     .word 25  # Steel string acoustic guitar
    
    # Volume (0-127)
    volume:         .word 100
    
    # Current selected string (0-5)
    current_string: .word 0

.text
.globl main
main:
    # Print welcome message
    li $v0, 4
    la $a0, welcome_msg
    syscall
    
    # Initialize current string to E2 (0)
    li $t0, 0
    sw $t0, current_string
    
    # Initialize all chord strings to 0 (not selected)
    la $t0, chord_strings
    li $t1, 0       # Counter
clear_chord_strings:
    sw $zero, 0($t0)  # Store 0
    addi $t0, $t0, 4  # Next word
    addi $t1, $t1, 1  # Increment counter
    blt $t1, 6, clear_chord_strings
    
input_loop:
    # Read character from keyboard
    li $v0, 12
    syscall
    move $t0, $v0  # Save input character
    
    # Check for quit command ('q')
    beq $t0, 'q', exit_program
    
    # Check if input is a digit (1-9 for frets)
    blt $t0, '1', check_string_keys
    bgt $t0, '9', check_string_keys
    
    # Play fretted note
    sub $t1, $t0, '0'  # Convert ASCII to integer (1-9)
    j play_fretted_note
    
check_string_keys:
    # Check if it's a chord key (z-x-c-v-b-n)
    la $t2, chord_key_map
    li $t3, 0               # index counter
    
check_chord_key:
    lb $t4, 0($t2)          # load key from map
    beq $t0, $t4, toggle_chord_string
    
    addi $t2, $t2, 1        # move to next key in map
    addi $t3, $t3, 1        # increment index
    
    blt $t3, 6, check_chord_key  # if not all keys checked, continue
    
    # Not a chord key, check regular string keys
    la $t2, key_map
    li $t3, 0               # index counter
    
check_key_loop:
    lb $t4, 0($t2)          # load key from map
    beq $t0, $t4, string_selected
    
    addi $t2, $t2, 1        # move to next key in map
    addi $t3, $t3, 1        # increment index
    
    blt $t3, 6, check_key_loop  # if not all keys checked, continue
    
    # Check if it's the spacebar to play the chord
    beq $t0, ' ', play_chord
    
    j input_loop            # key not found, get next input
    
string_selected:
    # Save the selected string
    sw $t3, current_string
    
    # Play the open string note
    li $t1, 0  # Fret 0 (open string)
    
play_fretted_note:
    # Get current string
    lw $t3, current_string
    
    # Calculate pitch based on string and fret
    sll $t4, $t3, 2         # multiply string index by 4 (word size)
    la $t5, string_pitches
    add $t5, $t5, $t4
    lw $t6, 0($t5)          # load base pitch value
    
    add $t6, $t6, $t1       # add fret number to pitch
    
    # Print which string/fret is being played
    li $v0, 4
    la $a0, string_played
    syscall
    
    # Print string name
    mul $t7, $t3, 3         # each string name is 3 bytes (including null)
    la $t8, string_names
    add $t8, $t8, $t7
    
    li $v0, 4
    move $a0, $t8
    syscall
    
    # Print fret number if not open string
    beqz $t1, skip_fret_display
    
    li $v0, 4
    la $a0, fret_played
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
skip_fret_display:
    li $v0, 4
    la $a0, newline
    syscall
    
    # Play the note
    li $v0, 33              # MIDI out synchronous
    move $a0, $t6           # pitch (base + fret)
    lw $a1, duration        # duration
    lw $a2, instrument      # instrument
    lw $a3, volume          # volume
    syscall
    
    j input_loop
    
# Toggle a string in the chord
toggle_chord_string:
    # Calculate address in chord_strings array
    sll $t4, $t3, 2         # multiply index by 4 (word size)
    la $t5, chord_strings
    add $t5, $t5, $t4
    
    # Toggle the value (0 -> 1, 1 -> 0)
    lw $t6, 0($t5)          # load current value
    xori $t6, $t6, 1        # toggle (0<->1)
    sw $t6, 0($t5)          # store new value
    
    # Provide feedback - either "added" or "removed" string from chord
    li $v0, 4
    beqz $t6, string_removed
    
    # String added to chord - play it immediately so user gets feedback
    la $a0, string_played
    syscall
    
    # Print string name
    mul $t7, $t3, 3         # each string name is 3 bytes (including null)
    la $t8, string_names
    add $t8, $t8, $t7
    
    li $v0, 4
    move $a0, $t8
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Play the string that was just added
    la $t9, string_pitches
    sll $t7, $t3, 2        # multiply index by 4 (word size)
    add $t9, $t9, $t7
    lw $t7, 0($t9)         # load pitch value
    
    # Play the note
    li $v0, 33              # MIDI out synchronous
    move $a0, $t7           # pitch
    lw $a1, duration        # duration
    lw $a2, instrument      # instrument
    lw $a3, volume          # volume
    syscall
    
    j input_loop
    
string_removed:
    # Indicate string was removed from chord
    la $a0, string_played
    syscall
    
    # Print string name that was removed
    mul $t7, $t3, 3         # each string name is 3 bytes (including null)
    la $t8, string_names
    add $t8, $t8, $t7
    
    li $v0, 4
    move $a0, $t8
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    j input_loop
    
# Play all selected strings in the chord
play_chord:
    # Print chord playing message
    li $v0, 4
    la $a0, chord_msg
    syscall
    
    # Check if any strings are selected
    la $t0, chord_strings
    li $t1, 0       # Counter for strings
    li $t2, 0       # Flag to check if any string is selected
    
check_any_selected:
    lw $t3, 0($t0)
    or $t2, $t2, $t3    # Update flag if any string is selected
    
    addi $t0, $t0, 4    # Next string
    addi $t1, $t1, 1
    blt $t1, 6, check_any_selected
    
    # If no strings selected, return to input loop
    beqz $t2, input_loop
    
    # Play all selected strings
    la $t0, chord_strings
    la $t1, string_pitches
    li $t2, 0       # Counter
    
play_next_string:
    lw $t3, 0($t0)      # Load string toggle (0/1)
    beqz $t3, skip_string
    
    # String is selected, play it
    lw $t4, 0($t1)      # Load pitch
    
    # Play the note non-synchronously (31 instead of 33)
    li $v0, 31
    move $a0, $t4       # pitch
    lw $a1, duration    # duration
    lw $a2, instrument  # instrument
    lw $a3, volume      # volume
    syscall
    
    # Small delay between notes for a strumming effect (20ms)
    li $v0, 32          # sleep syscall
    li $a0, 20          # 20ms delay between strings
    syscall
    
skip_string:
    addi $t0, $t0, 4    # Move to next chord_string
    addi $t1, $t1, 4    # Move to next pitch
    addi $t2, $t2, 1
    
    blt $t2, 6, play_next_string
    
    # Sleep for the duration to let the chord sound
    li $v0, 32          # sleep syscall
    lw $a0, duration    # sleep for duration ms
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