.data
    welcome_msg:    .asciiz "Virtual Guitar Simulator\n\nIndividual Notes:\n- Press keys a-s-d-f-g-h to play open strings (E2, A2, D3, G3, B3, E4)\n- Press 1-9 to play frets on the current string\n\nChord Mode:\n- Press z-x-c-v-b-n to play and toggle strings for chord\n- Press SPACE to strum all selected strings\n- Press 'u' for up strum, 'd' for down strum\n\nPress 'q' to quit\n"
    quit_msg:       .asciiz "\nExiting Virtual Guitar...\n"
    string_played:  .asciiz "Playing string: "
    fret_played:    .asciiz " fret: "
    chord_msg:      .asciiz "Playing chord with strum pattern: "
    newline:        .asciiz "\n"
    up_strum_msg:   .asciiz "up strum"
    down_strum_msg: .asciiz "down strum"
    palm_mute_on_msg: .asciiz "Palm mute ON"
    palm_mute_off_msg: .asciiz "Palm mute OFF"
    hammer_on_on_msg: .asciiz "Hammer-on/pull-off mode ON"
    hammer_on_off_msg: .asciiz "Hammer-on/pull-off mode OFF"
    instrument_change_msg: .asciiz "Changed instrument to: "
    
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
    
    # MIDI instrument values
    instruments:    .word 24, 25, 26, 27, 28, 29, 30  # Different guitar types
    instrument:     .word 25  # Default: Steel string acoustic guitar
    
    # Volume (0-127)
    volume:         .word 100
    
    # Current selected string (0-5)
    current_string: .word 0
    
    # Strum patterns
    up_strum_order: .word 5, 4, 3, 2, 1, 0  # High E to low E
    down_strum_order: .word 0, 1, 2, 3, 4, 5 # Low E to high E
    random_strum_order: .word 0, 0, 0, 0, 0, 0
    
    # String volumes to simulate finger position
    string_volumes: .word 100, 95, 90, 85, 80, 75
    
    # Hammer-on/pull-off flag
    hammer_on:      .word 0
    
    # Last played note for hammer-on/pull-off
    last_note:      .word -1
    last_time:      .word 0
    
    # Current tempo (ms per beat)
    tempo:          .word 500
    
    # Palm mute flag
    palm_mute:      .word 0

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
    
    # Check for palm mute toggle ('m')
    beq $t0, 'm', toggle_palm_mute
    
    # Check for hammer-on/pull-off toggle ('p')
    beq $t0, 'p', toggle_hammer_on
    
    # Check for instrument change ('i')
    beq $t0, 'i', next_instrument
    
    # Check for up strum ('u')
    beq $t0, 'u', play_up_strum
    
    # Check for down strum ('d')
    beq $t0, 'd', play_down_strum
    
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
    
    # Check if it's the spacebar to play the chord with random strum
    beq $t0, ' ', play_random_strum
    
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
    
    # Check for hammer-on/pull-off
    lw $t7, hammer_on
    beqz $t7, normal_play   # if hammer-on disabled, play normally
    
    # Get current time
    li $v0, 30
    syscall
    move $t8, $a0           # current time in ms
    
    lw $t9, last_time
    sub $t9, $t8, $t9       # time since last note
    
    # If time since last note < 200ms and same string, it's a hammer-on/pull-off
    lw $s0, last_note
    bne $s0, $t3, normal_play  # different string
    li $s1, 200
    bge $t9, $s1, normal_play  # too much time passed
    
    # Hammer-on/pull-off - play with shorter duration and different volume
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
    beqz $t1, skip_fret_display_ho
    
    li $v0, 4
    la $a0, fret_played
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
skip_fret_display_ho:
    li $v0, 4
    la $a0, newline
    syscall
    
    # Play the note with hammer-on/pull-off characteristics
    li $v0, 33              # MIDI out synchronous
    move $a0, $t6           # pitch (base + fret)
    li $a1, 300             # shorter duration for hammer-on
    lw $a2, instrument      # instrument
    li $a3, 110             # slightly louder for hammer-on
    syscall
    
    j update_last_note
    
normal_play:
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
    
    # Adjust volume based on string (higher strings are quieter)
    la $t7, string_volumes
    sll $t8, $t3, 2
    add $t7, $t7, $t8
    lw $t8, 0($t7)          # get string-specific volume
    
    # Apply palm mute if active
    lw $t9, palm_mute
    beqz $t9, no_palm_mute
    srl $t8, $t8, 1         # halve volume for palm mute
    li $a1, 300              # shorter duration for palm mute
    
no_palm_mute:
    # Play the note
    li $v0, 33              # MIDI out synchronous
    move $a0, $t6           # pitch (base + fret)
    lw $a1, duration        # duration
    lw $a2, instrument      # instrument
    move $a3, $t8           # adjusted volume
    syscall
    
update_last_note:
    # Store last played note info for hammer-on/pull-off
    sw $t3, last_note       # store string index
    li $v0, 30              # get system time
    syscall
    sw $a0, last_time       # store time
    
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
    li $a1, 300             # shorter duration for chord preview
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
    
# Play chord with random strum pattern
play_random_strum:
    # Generate a semi-random strum pattern (alternating up/down)
    li $v0, 30              # get system time
    syscall
    andi $t0, $a0, 1        # use LSB of time to decide up/down
    beqz $t0, play_down_strum
    j play_up_strum
    
# Play chord with up strum (high E to low E)
play_up_strum:
    # Print chord playing message
    li $v0, 4
    la $a0, chord_msg
    syscall
    la $a0, up_strum_msg
    syscall
    la $a0, newline
    syscall
    
    la $s0, up_strum_order  # load pattern address
    j play_strum_pattern
    
# Play chord with down strum (low E to high E)
play_down_strum:
    # Print chord playing message
    li $v0, 4
    la $a0, chord_msg
    syscall
    la $a0, down_strum_msg
    syscall
    la $a0, newline
    syscall
    
    la $s0, down_strum_order # load pattern address
    
play_strum_pattern:
    # Check if any strings are selected
    la $t0, chord_strings
    li $t1, 0       # Counter for strings
    li $t2, 0       # Flag to check if any string is selected
    
check_any_selected_strum:
    lw $t3, 0($t0)
    or $t2, $t2, $t3    # Update flag if any string is selected
    
    addi $t0, $t0, 4    # Next string
    addi $t1, $t1, 1
    blt $t1, 6, check_any_selected_strum
    
    # If no strings selected, return to input loop
    beqz $t2, input_loop
    
    # Play all selected strings in strum pattern order
    li $t2, 0       # Counter
    
play_next_string_strum:
    # Get string index from pattern
    sll $t3, $t2, 2
    add $t3, $s0, $t3
    lw $t3, 0($t3)      # string index from pattern
    
    # Check if this string is selected
    sll $t4, $t3, 2
    la $t5, chord_strings
    add $t5, $t5, $t4
    lw $t6, 0($t5)      # load string toggle
    beqz $t6, skip_string_strum
    
    # String is selected, play it
    la $t7, string_pitches
    add $t7, $t7, $t4
    lw $t7, 0($t7)      # load pitch
    
    # Adjust volume based on string position
    la $t8, string_volumes
    add $t8, $t8, $t4
    lw $t8, 0($t8)
    
    # Apply palm mute if active
    lw $t9, palm_mute
    beqz $t9, no_palm_mute_strum
    srl $t8, $t8, 1     # halve volume for palm mute
    
no_palm_mute_strum:
    # Play the note non-synchronously (31 instead of 33)
    li $v0, 31
    move $a0, $t7       # pitch
    li $a1, 400         # slightly shorter duration for strumming
    lw $a2, instrument  # instrument
    move $a3, $t8       # adjusted volume
    syscall
    
    # Variable delay between notes for more natural strumming
    li $v0, 32          # sleep syscall
    li $a0, 60          # 60ms delay between strings
    sub $a0, $a0, $t2   # decrease delay for later strings
    sll $a0, $a0, 1     # scale the effect
    syscall
    
skip_string_strum:
    addi $t2, $t2, 1
    blt $t2, 6, play_next_string_strum
    
    # Sleep for the remaining duration to let the chord sound
    li $v0, 32          # sleep syscall
    li $a0, 300         # sleep for remaining duration
    syscall
    
    j input_loop
    
# Toggle palm mute
toggle_palm_mute:
    lw $t0, palm_mute
    xori $t0, $t0, 1
    sw $t0, palm_mute
    
    # Print status
    li $v0, 4
    beqz $t0, palm_mute_off
    la $a0, palm_mute_on_msg
    j print_palm_status
    
palm_mute_off:
    la $a0, palm_mute_off_msg
    
print_palm_status:
    syscall
    la $a0, newline
    syscall
    j input_loop
    
# Toggle hammer-on/pull-off mode
toggle_hammer_on:
    lw $t0, hammer_on
    xori $t0, $t0, 1
    sw $t0, hammer_on
    
    # Print status
    li $v0, 4
    beqz $t0, hammer_on_off
    la $a0, hammer_on_on_msg
    j print_hammer_status
    
hammer_on_off:
    la $a0, hammer_on_off_msg
    
print_hammer_status:
    syscall
    la $a0, newline
    syscall
    j input_loop
    
# Cycle to next instrument
next_instrument:
    lw $t0, instrument
    la $t1, instruments
    li $t2, 0           # counter
    
find_current_instrument:
    lw $t3, 0($t1)
    beq $t3, $t0, found_instrument
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j find_current_instrument
    
found_instrument:
    addi $t2, $t2, 1
    li $t4, 7           # number of instruments
    div $t2, $t4
    mfhi $t2            # wrap around
    
    sll $t2, $t2, 2
    la $t1, instruments
    add $t1, $t1, $t2
    lw $t0, 0($t1)
    sw $t0, instrument
    
    # Print new instrument
    li $v0, 4
    la $a0, instrument_change_msg
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, newline
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