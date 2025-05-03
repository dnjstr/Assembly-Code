.data
    welcome_msg:    .asciiz "Virtual Drum Machine (1-Second Notes)\n"
    instructions:   .asciiz "Press keys a-l to play drums, q to quit:\n"
    drum_kit:       .asciiz "a=Bass, s=Snare, d=Hi-Hat, f=Crash, g=Tom1, h=Tom2, j=Tom3, k=Ride, l=Clap\n"
    playing:        .asciiz "Playing: "
    bass_msg:       .asciiz "Bass Drum (1 second)\n"
    snare_msg:      .asciiz "Snare Drum (1 second)\n"
    hihat_msg:      .asciiz "Hi-Hat (1 second)\n"
    crash_msg:      .asciiz "Crash Cymbal (1 second)\n"
    tom1_msg:       .asciiz "Tom 1 (1 second)\n"
    tom2_msg:       .asciiz "Tom 2 (1 second)\n"
    tom3_msg:       .asciiz "Tom 3 (1 second)\n"
    ride_msg:       .asciiz "Ride Cymbal (1 second)\n"
    clap_msg:       .asciiz "Hand Clap (1 second)\n"
    quit_msg:       .asciiz "\nExiting Drum Machine...\n"
    
    # MIDI drum notes (percussion channel is 10)
    bass_drum:      .word 35
    snare:         .word 38
    hihat:         .word 42
    crash:         .word 49
    tom1:          .word 41
    tom2:          .word 43
    tom3:          .word 45
    ride:          .word 51
    clap:          .word 39
    
    # Key mappings (a-l)
    drum_keys:      .byte 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'
    drum_notes:     .word 35, 38, 42, 49, 41, 43, 45, 51, 39
    drum_messages:  .word bass_msg, snare_msg, hihat_msg, crash_msg, tom1_msg, tom2_msg, tom3_msg, ride_msg, clap_msg
    
    # Duration and settings (changed to 1000ms)
    duration:       .word 1000    # 1 second (1000ms)
    channel:        .word 9       # MIDI channel 10 (0-based)
    volume:         .word 100

.text
.globl main

main:
    # Print welcome message
    li $v0, 4
    la $a0, welcome_msg
    syscall
    la $a0, instructions
    syscall
    la $a0, drum_kit
    syscall

input_loop:
    # Read character from keyboard
    li $v0, 12
    syscall
    
    # Check for quit command
    beq $v0, 'q', exit_program
    
    # Check which drum was pressed
    la $t0, drum_keys
    li $t1, 0               # index counter
    
check_drum:
    lb $t2, 0($t0)          # load key from map
    beq $v0, $t2, play_drum
    
    addi $t0, $t0, 1        # move to next key in map
    addi $t1, $t1, 1        # increment index
    
    blt $t1, 9, check_drum  # if not all keys checked, continue
    j input_loop            # key not found, get next input
    
play_drum:
    # Print which drum is being played
    li $v0, 4
    la $a0, playing
    syscall
    
    # Print drum name
    sll $t3, $t1, 2         # multiply index by 4 (word size)
    la $t4, drum_messages
    add $t4, $t4, $t3
    lw $a0, 0($t4)
    syscall
    
    # Play the drum sound for 1 second
    la $t5, drum_notes
    add $t5, $t5, $t3
    lw $a0, 0($t5)          # drum note
    
    li $v0, 33              # MIDI out synchronous
    lw $a1, duration        # 1000ms duration
    li $a2, 0               # instrument doesn't matter for percussion
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