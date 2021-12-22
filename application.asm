.data
    filepath:			    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images/input.pgm"
    last_char:              .word 0
    num_rows:               .word 0
    num_columns:            .word 0
    num_files:              .word 0
    valmax:                 .word 1
    maximum_valmax_length:  .word 5
    bl:                     .asciiz "\n"
    space:                  .asciiz " " 
    char:                   .asciiz 
    filepath_output:	    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/output.pgm"
    output_header:          .asciiz "P2\n# output.pgm\n"
    fourth_line:            .word 0
    fourth_line_length:     .word 0
.text

main:
    jal read_args               # read the header of the pgm file

    jal create_matrix_int       # stores the sum of all matrices
    move $s0, $v0
    jal create_matrix_string    # serves as a temporary matrix before being converted to int
    move $s1, $v0

    jal open_file
    move $s2, $v0               # file_descriptor

    main_loop:
        move $a0, $s1
        move $a1, $s2
        jal read_file           # read one file per loop
        move $s3, $v0           # EOF
        
        move $a0, $s1
        jal matrix_string_to_matrix_int # converting a char matrix to integer matrix
        move $t0, $v0

        move $a0, $s0
        move $a1, $t0
        jal sum_two_matrices            # summinng matrices 

        beq $s3, 1, main_division_and_writing  # if (EOF == true) break

        j main_loop

    main_division_and_writing:
    move $a0, $s0 
    lw $a1, num_files 
    jal divide_matrix_by_constant       # dividing all matrices by the number of files


    move $a0, $s0
    jal matrix_int_to_matrix_string     # converting a integer matrix to a char matrices
    move $s1, $v0

    move $a0, $s1
    li $a1, 5
    jal write_file                      # writing output

    main_exit:
    move $a0, $s2
    jal close_file

    li $v0, 10
    syscall

divide_matrix_by_constant:
    # args: $a0 - matrix_address, $a1 - division_factor
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0       # matrix_address
    move $s1, $a1       # division_factor    
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1   # matrix_length
    li $s3, 0           # counter
    # li $s4, 0         # m_result_address

    dmbc_loop:
        beq $s3, $s2, dmbc_end  # if (counter == matrix_length) break

        lw $t0, 0($s0)          # pos
        div $t1, $t0, $s1       # matrix[counter] / division_factor

        sw $t1, 0($s0)          # matrix[counter] = matrix[counter] / division_factor

        addi $s0, $s0, 4        # matrix_address++
        addi $s3, $s3, 1        # counter++

        j dmbc_loop

    dmbc_end:
    move $v0, $s4

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return:

sum_two_matrices:
    # args: $a0 - m0, $a1 - m1
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0       # m0_address
    move $s1, $a1       # m1_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1   # matrix_length
    li $s3, 0           # counter
    li $s4, 0           # m_result_address

    # create matrix_int buffer
    li $v0, 9
    move $a0, $s2         # matrix_length 
    syscall 
    move $s4, $v0

    stm_loop:
        beq $s3, $s2, stm_end   # if (counter == matrix_length) break

        li $t0, 4               # sizeof(int)
        mul $t1, $s3, $t0   
        add $t1, $t1, $s0       # pos0 = m0_address + (counter * sizeof(int))
        mul $t2, $s3, $t0
        add $t2, $t2, $s1       # pos1 = m1_address + (counter * sizeof(int))
        
        lw $t4, 0($t1)
        lw $t5, 0($t2)

        add $t6, $t4, $t5       # m0[counter] + m1[counter]
        sw $t6, 0($t1)          # m0[counter] = m0[counter] + m1[counter]

        # updating (maybe) the valmax
        move $a0, $t5
        jal update_max_val

        addi $s3, $s3, 1        # counter++

        j stm_loop

    stm_end:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return: 

read_args:
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw  $s0, 0($sp)    
    sw  $s1, 4($sp)    
    sw  $s2, 8($sp)    
    sw  $s3, 12($sp)    
    sw  $s4, 16($sp)    
    sw  $ra, 20($sp)

    li $s0, 1            # rows_counter
    li $s1, 1            # columns_counter
    li $s2, 0            # buffer_address
    li $s3, 0            # file_descriptor
    lw $s4, last_char    # last_char : 0 - not-a-whitespace, 1 - whitespace

    jal open_file
    move $s3, $v0      # file_descriptor

    # create the buffer 
    li $v0, 9
    li $a0, 1
    syscall
    move $s2, $v0   # buffer address
    
    ra_loop:
        # read from file
        li $v0, 14    	# system call for read from file
        move $a0, $s3   # file descriptor 
        move $a1, $s2   # address of buffer to which to read
        li $a2, 1       # hardcoded buffer length
        syscall         # read from file
        move $t0, $v0   # how many bytes were read
        
        li $v0, -1              # return case EOF
        beq $t0, 0, ra_exit   # return case EOF

        lw $s4, last_char       # old_last_char

        lb $t0, 0($s2)
        move $a0, $t0
        jal is_number_or_whitespace
        beq $v0, 0, ra_EOF                # if the char just read is a letter, branch
        
        lb $t0, 0($s2)
        move $a0, $t0
        jal handle_whitespace_if_any
        lw $t0, last_char                 # new_last_char
        beq $s4, $t0, ra_loop             # last_char whitespace repeating! Do not count again

        lb $t1, 0($s2)                    # last_read_char

        increasing_values_ra:
        # 0 = not_white_space, 1 = space_or_tab, 2 = bl
        beq $v0, 0, ra_loop                 # write the number just read
        beq $v0, 2, increase_num_rows_ra    # increase_num_rows_ra
        beq $v0, 1, increase_num_columns_ra # increase_num_columns_ra

        increase_num_columns_ra:
        li $t0, 5
        bne $s0, $t0, ra_loop   # if (rows_counter != 5) break 

        addi $s1, $s1, 1
        j ra_loop

        increase_num_rows_ra:
        addi $s0, $s0, 1
        j ra_loop

        increase_matrix_address_ra:
        addi $s5, $s5, 5    # matrix_string_address += 5

        li $s6, 0           # string_pos = 0

        j ra_loop

        ra_EOF:
        # if there's a letter after the 4º line, the program is re-reading the header
        bgt $s0, 4, ra_exit 
        # else
        j ra_loop

    ra_exit:
    addi $s0, $s0, -5       # subtracting 4 lines from the header and 1 from the line that is after
    sw $s0, num_rows
    sw $s1, num_columns

    move $a0, $s3
    jal close_file

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra

handle_whitespace_if_any:
    # args: $a0 - char
    addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
    sw  $s0, 0($sp)
    sw  $ra, 4($sp)

    li $s0, 0   # return_value          
                                    # 0 = not_white_space, 1 = space_or_tab, 2 = bl
    beq $a0, 9, is_space_or_tab     # horizontal tab
    beq $a0, 10, is_bl              # line feed
    beq $a0, 11, is_space_or_tab    # vertical tab
    beq $a0, 13, is_bl              # carriage return
    beq $a0, 32, is_space_or_tab    # space	
    li $t0, 0                       # if not whitespace: last_char = 0
    sw $t0, last_char
    j hwif_exit
    is_space_or_tab:
    li $t0, 1               # last_char = 1
    sw $t0, last_char
    li $s0, 1
    j hwif_exit
    is_bl:
    li $s0, 2
    li $t0, 1               # last_char = 1
    sw $t0, last_char
    j hwif_exit
    hwif_exit:
    move $v0, $s0
    lw  $s0, 0($sp)
    lw  $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
    # returns 0 = not_white_space, 1 = space_or_tab, 2 = bl

update_max_val:
    # args: $a0 - val
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    lw $s0, valmax
    move $s1, $a0

    blt $s1, $s0, umv_exit      # if (input < valmax) ignore

    increase_valmax_umv:
    sw $s1, valmax

    move $a0, $s1
    jal get_int_length
    move $s2, $v0
    sw $s2, fourth_line_length

    move $a0, $s1
    move $a1, $s2
    jal convert_int_to_string
    move $s0, $v0
    sw $s0, fourth_line

    umv_exit:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return:

get_int_length:
    # args: $a0 - number
    addi $sp, $sp, -16	# 4 register * 4 bytes = 16 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $ra, 12($sp)

    move $s0, $a0   # number
    li $s1, 1       # length
    li $s2, 10      # cur_decimal_place

    li $t0, -1
    bgt $s0, $t0, gil_loop      # if (number >= 0) continue
    mul $s0, $s0, $t0           # else

    gil_loop:
        blt $s0, $s2, gil_exit  # if (number < cur_decimal_place) break
        # else
        addi $s1, $s1, 1        # length++
        mul $s2, $s2, 10        # cur_decimal_place *= 10
        j gil_loop
    

    gil_exit:
    move $v0, $s1

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    # return: $v0 - length

write_file:
    # args: $a0 - matrix_address, $a1 - sizeof(string)
    addi $sp, $sp, -36	# 9 register * 4 bytes = 36 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $s3, 12($sp)
    sw  $s4, 16($sp)
    sw  $s5, 20($sp)
    sw  $s6, 24($sp)
    sw  $s7, 28($sp)
    sw  $ra, 32($sp)

    li $s0, 0               # file_description
    move $s1, $a0           # matrix_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1
    lw $t2, maximum_valmax_length
    mul $s2, $s2, $t2       # matrix_length
    li $s3, 0               # num_rows_str
    li $s4, 0               # num_rows_str_length
    li $s5, 0               # num_columns_str
    li $s6, 0               # num_columns_str_length
    li $s7, 0               # counter

    jal open_file_to_write
    move $s0, $v0
    
    # writing first two lines
    li $v0, 15
    move $a0, $s0
    la $a1, output_header
    la $a2, 16
    syscall

    # printing third and fourth lines
    lw $a0, num_rows 
    jal get_int_length
    move $s4, $v0
    lw $a0, num_rows 
    move $a1, $s4
    jal convert_int_to_string
    move $s3, $v0

    lw $a0, num_columns 
    jal get_int_length
    move $s6, $v0
    lw $a0, num_columns 
    move $a1, $s6
    jal convert_int_to_string
    move $s5, $v0

    # writing num_rows
    li $v0, 15
    move $a0, $s0
    move $a1, $s3
    move $a2, $s4
    syscall 

    # writing space
    li $v0, 15
    move $a0, $s0
    la $a1, space
    li $a2, 1
    syscall 

    # writing num_columns
    li $v0, 15
    move $a0, $s0
    move $a1, $s5
    move $a2, $s6
    syscall 

    # writing bl
    li $v0, 15
    move $a0, $s0
    la $a1, bl
    li $a2, 1
    syscall 

    # writing fourth_line
    li $v0, 15
    move $a0, $s0
    lw $a1, fourth_line
    lw $a2, fourth_line_length
    syscall 

    # writing bl
    li $v0, 15
    move $a0, $s0
    la $a1, bl
    li $a2, 1
    syscall 

    li $s7, 0       # counter
    # writing rest of the file
    wf_loop:
        beq $s7, $s2, wf_exit   # if (counter == matrix_length) break

        add $t0, $s1, $s7       # pos = matrix_address + counter 

        wf_printing_number:
        # if (read_number == null) ignore
        lb $t1, 0($t0)
        li $t2, 0
        beq $t1, $t2, wf_printing_whitespace    

        # else
        li $v0, 15
        move $a0, $s0
        move $a1, $t0
        li $a2, 1
        syscall 

        wf_printing_whitespace:
        addi $t0, $s7, 1                    # counter_tmp = counter + 1 (to the modulo works)
        lw $t1, num_columns
        lw $t2, maximum_valmax_length
        mul $t1, $t1, $t2
        div $t0, $t1            
        mfhi $t0                            # counter_tmp % (num_columns * maximum_valmax_length)
        li $t1, 0
        beq $t0, $t1, wf_ĺoop_print_bl      # if (counter_tmp % num_columns == 0) print_bl

        addi $t0, $s7, 1                    # counter_tmp = counter + 1 (to the modulo works)
        lw $t1, maximum_valmax_length
        div $t0, $t1            
        mfhi $t0                            # counter_tmp % maximum_valmax_length
        li $t1, 0
        beq $t0, $t1, wf_ĺoop_print_space   # if (counter_tmp % maximum_valmax_length == 0) print_space
    
        # else continue
        addi $s7, $s7, 1        # counter++
        j wf_loop

        wf_ĺoop_print_space:
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall 

        addi $s7, $s7, 1        # counter++

        j wf_loop

        wf_ĺoop_print_bl:
        li $v0, 15
        move $a0, $s0
        la $a1, bl
        li $a2, 1
        syscall

        addi $s7, $s7, 1        # counter++

        j wf_loop

    wf_exit:
    move $a0, $s0
    jal close_file

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $s5, 20($sp)
    lw  $s6, 24($sp)
    lw  $s7, 28($sp)
    lw  $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra

open_file_to_write:
    addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
    sw  $ra, 0($sp)

    li   $v0, 13                    # system call for open file
    la   $a0, filepath_output       # output file name
    li   $a1, 1                     # Open for writing (flags are 0: read, 1: write)
    li   $a2, 0                     # mode is ignored
    syscall                         # open a file (file_descriptor returned in $v0)
    # move $v0, $v0                 # save the file_descriptor 

    lw  $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


convert_string_to_int:
    # args: $a0 - buffer, $a1 - str length
    addi $sp, $sp, -28	# 7 register * 4 bytes = 28 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $ra, 24($sp)

    move $s0, $a0       # buffer_address
    move $s1, $a1       # buffer_length
    # move $s2, $a0     # buffer_address_tmp -> not in use
    li $s3, 1           # decimal_place
    move $s4, $s1       # buffer_address_pos           
    addi $s4, $s4, -1   # subtracting 1 because the array first index is 0    
    li $s5, 0           # int value        


    sti_loop:
        blt $s4, 0, sti_exit # if (buffer_address_pos < 0) break

        add $t0, $s0, $s4    # buffer_address[pos]
        lb $t1, 0($t0)
        li $t2, 0
        beq $t1, $t2, sti_loop_increment  # if (buffer_address[pos] == 0) continue  

        addi $t1, $t1, -48  # converting char to int
        mul $t1, $t1, $s3   # num = num * decimal_place
        add $s5, $s5, $t1   # value += num

        mul $s3, $s3, 10    # decimal_place *= 10

        sti_loop_increment:
        # addi $s2, $s2, 1    # buffer_address_tmp++
        addi $s4, $s4, -1   # buffer_address_pos--

        j sti_loop

    sti_exit:
    move $v0, $s5
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra
    # return: $v0 - buffer_address

open_file:
        addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
        sw  $ra, 0($sp)

        # open a file for reading
        li $v0, 13        # system call for open file
        la $a0, filepath
        li $a1, 0         # Open for reading
        li $a2, 0
        syscall            # open a file (file descriptor returned in $v0)

        # move $v0, $v0
        lw  $ra, 0($sp)
        addi $sp, $sp, 4

        jr $ra
        # return file_descriptor

read_file:
    # args: $a0 - matrix_string_address, $a1 - file_descriptor
    addi $sp, $sp, -28	# 8 register * 4 bytes = 32 bytes 
    sw  $s0, 0($sp)    
    sw  $s1, 4($sp)    
    sw  $s2, 8($sp)    
    sw  $s3, 12($sp)    
    sw  $s4, 16($sp)    
    sw  $s5, 20($sp)    
    sw  $s6, 24($sp)    
    sw  $ra, 28($sp)

    li $s0, 1          # rows_counter
    li $s1, 1          # columns_counter
    li $s2, 0          # buffer_address
    move $s3, $a1      # file_descriptor
    lw $s4, last_char  # last_char : 0 - not-a-whitespace, 1 - whitespace
    move $s5, $a0      # matrix_string_buffer
    li $s6, 0          # string_pos

    # create the buffer 
    li $v0, 9
    li $a0, 1
    syscall
    move $s2, $v0   # buffer address
    
    rf_loop:
        # read from file
        li $v0, 14    	# system call for read from file
        move $a0, $s3   # file descriptor 
        move $a1, $s2   # address of buffer to which to read
        li $a2, 1       # hardcoded buffer length
        syscall         # read from file
        move $t0, $v0   # how many bytes were read
        
        li $v0, 1               # EOF = true
        beq $t0, 0, rf_return   # return case EOF

        lw $s4, last_char       # old_last_char

        lb $t0, 0($s2)
        move $a0, $t0
        jal is_number_or_whitespace
        beq $v0, 0, rf_EOF      # if the char just read is a letter, branch

        lb $t0, 0($s2)
        move $a0, $t0
        jal handle_whitespace_if_any
        lw $t0, last_char                 # new_last_char
        bne $t0, 1, increasing_values_rf  # if last_char isn't a whitespace, continue
        beq $s4, $t0, rf_loop             # last_char whitespace repeating! Do not count again

        lb $t1, 0($s2)                    # last_read_char

        increasing_values_rf:
        # 0 = not_white_space, 1 = space_or_tab, 2 = bl
        beq $v0, 0, write_in_matrix_rf      # write the number just read
        beq $v0, 2, increase_num_rows_rf    # increase_num_rows_rf
        beq $v0, 1, increase_num_columns_rf # increase_num_columns_rf

        write_in_matrix_rf:
        li $t0, 5
        blt $s0, $t0, rf_loop       # if (rows_counter < 5) continue

        lb $t1, 0($s2)              # last_read_char

        add $t0, $s5, $s6           # pos = matrix_string_address + string_pos
        lb $t1, ($s2)               # last_read_char
        sb $t1, ($t0)               # matrix_string_address[pos] = last_read_char

        addi $s6, $s6, 1            # string_pos++

        j rf_loop

        increase_num_columns_rf:
        # addi $s1, $s1, 1
        li $t0, 5
        blt $s0, $t0, rf_loop           # if (rows_count < 5) continue
        j increase_matrix_address_rf

        increase_num_rows_rf:
        addi $s0, $s0, 1
        li $t0, 6
        blt $s0, $t0, rf_loop           # if (rows_count < 6) continue
        j increase_matrix_address_rf

        increase_matrix_address_rf:
        addi $s5, $s5, 5    # matrix_string_address += 5

        li $s6, 0           # string_pos = 0

        j rf_loop

        rf_EOF:
        # if there's a letter after the 4º line, the program is re-reading the header
        li $v0, 0         # EOF = false
        bgt $s0, 4, rf_return 
        # else
        j rf_loop

    rf_return:
    lw $t0, num_files
    addi $t0, $t0, 1
    sw $t0, num_files

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $s5, 20($sp)
    lw  $s6, 24($sp)
    lw  $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra
    # return: $v0 - EOF

close_file:
    # args: $a0 - file_descriptor
    addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
    sw  $s0, 0($sp)
    sw  $ra, 4($sp)

    move $s0, $a0       # file_descritor

    # Close the file 
    li   $v0, 16                # system call for close file
    # move $a0, $a0             # file descriptor to close
    syscall                     # close file

    lw  $s0, 0($sp)
    lw  $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

is_number_or_whitespace:
    # args: $a0 - buffer
    addi $sp, $sp, -12	# 3 register * 4 bytes = 12 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $ra, 8($sp)

    li $s0, 0           # is_number_or_whitespace
    move $s1, $a0       # $a0

    # if it's a whitespace, return false
    inan_first_check:
    move $a0, $s1
    jal handle_whitespace_if_any    
    bne $v0, 0, indeed_number_or_whitespace                                      
    
    # if $a0 < 48 then is not a number
    inan_second_check:
    li $t0, 48
    blt $s1, $t0, inan_return	
    
    # if $a0 > 57 then is not a number
    inan_third_check:
    li $t0, 57
    bgt $s1, $t0, inan_return	

    # else it is a number

    indeed_number_or_whitespace:
    li $s0, 1
    
    inan_return:
    move $v0, $s0
    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    # returns true or false


create_matrix_int:
    # args: 
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    li $s0, 0           # matrix_int_address
    li $s1, 0           # matrix_int_address_tmp
    li $s2, 0           # matrix_length
    li $s3, 0           # counter

    
    lw $t0, num_rows
    lw $t1, num_columns

    mul $s2, $t0, $t1   # matrix_length = num_rows * num_columns

    # matrix_int_size = num_rows * num_columns * size(int)
    mul $t2, $t0, $t1
    li $t3, 4           # sizeof(int)
    mul $t2, $t2, $t3

    # create matrix_int buffer
    li $v0, 9
    move $a0, $t2         # matrix_int_size 
    syscall 
    move $s0, $v0

    move $s1, $s0       # matrix_int_address_tmp = matrix_int_address
    li $s3, 0           # counter = 0
    # set matrix_int all to 0s
    cm_int_loop:
        beq $s3, $s2, cm_int_exit       # if (counter == matrix_length) break

        li $t0, 0
        sw $t0, ($s1)               # matrix_int[counter] = 0

        addi $s1, $s1, 4            # matrix_int++
        addi $s3, $s3, 1            # counter++

        j cm_int_loop


    cm_int_exit:
    # return matrix_int_address
    move $v0, $s0
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return: $v0 - matrix_int_address

create_matrix_string:
    # args: 
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    li $s0, 0                       # matrix_string_address
    lw $s1, maximum_valmax_length   # matrix_string_unit_size 
    li $s2, 0                       # matrix_string_address_tmp
    li $s3, 0                       # matrix_length
    li $s4, 0                       # counter
    
    lw $t0, num_rows
    lw $t1, num_columns

    mul $s3, $t0, $t1   # matrix_length = num_rows * num_columns * sizeof(string)
    mul $s3, $s3, 5

    # matrix_string_size = num_rows * num_columns * matrix_string_unit_size
    mul $t2, $t0, $t1   
    mul $t2, $t2, $s1

    # create matrix_string buffer
    li $v0, 9
    move $a0, $t2         # matrix_string_size 
    syscall 
    move $s0, $v0

    move $s2, $s0       # matrix_int_address_tmp = matrix_int_address
    li $s4, 0           # counter = 0
    # set matrix_string all to 0s
    cm_string_loop:
        beq $s4, $s3, cm_string_exit    # if (counter == matrix_length) break  

        li $t0, 0
        sb $t0, ($s2)                   # matrix_string[counter] = 0

        addi $s2, $s2, 1                # matrix_string++
        addi $s4, $s4, 1                # counter++

        j cm_string_loop
    
    cm_string_exit:
    move $v0, $s0
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return: $v0 - matrix_string_address

print_matrix_int:
        # args: $a0 - buffer
        addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $s2, 8($sp)
        sw $s3, 12($sp)
        sw $s4, 16($sp)
        sw $ra, 20($sp)

        move $s0, $a0           # matrix_address
        lw $s1, num_rows        # num_rows
        lw $s2, num_columns     # num_columns
        li $s3, 0               # counter
        li $s4, 4               # sizeof(int)

        pmi_loop:
            # last_pos = num_rows * num_columns
            mul $t0, $s1, $s2       
            beq $s3, $t0, pmi_end   # if (counter == last_pos) return

            lw $t0, 0($s0)           # matrix_address[counter]
            # print int
            li $v0, 1
            move $a0, $t0
            syscall

            addi $t0, $s3, 1            # counter_tmp = counter + 1 
            div $t0, $s2               # added 1 to the mod calculate correctly
            mfhi $t1                    # (counter + 1) % num_columns
            li $t2, 0
            beq $t1, $t2, pmi_print_bl  # if ((counter + 1) % num_columns == 0) print_bl
            
            # else print_space 
            pmi_print_space:
            li $v0, 4
            la $a0, space
            syscall

            add $s0, $s0, $s4        # matrix_address += sizeof(int)    
            addi $s3, $s3, 1        # counter++
            j pmi_loop

            pmi_print_bl:
            li $v0, 4
            la $a0, bl
            syscall

            add $s0, $s0, $s4        # matrix_address++    
            addi $s3, $s3, 1        # counter++
            j pmi_loop

        pmi_end:
        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $s2, 8($sp)
        lw $s3, 12($sp)
        lw $s4, 16($sp)
        lw $ra, 20($sp)
        addi $sp, $sp, 24
        jr $ra
    # return: 

print_matrix_string_int:
        # args: $a0 - buffer, $a1 - num_rows, $a2 - num_columns
        addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $s2, 8($sp)
        sw $s3, 12($sp)
        sw $s4, 16($sp)
        sw $ra, 20($sp)

        move $s0, $a0           # matrix_address
        move $s1, $a1           # num_rows
        move $s2, $a2           # num_columns
        li $s3, 0               # counter
        li $s4, 1               # sizeof(char)

        pmsi_loop:
            # last_pos = num_rows * num_columns
            mul $t0, $s1, $s2       
            beq $s3, $t0, pmsi_end   # if (counter == last_pos) return

            lb $t0, 0($s0)           # matrix_address[counter]
            # print int
            li $v0, 1
            move $a0, $t0
            syscall

            addi $t0, $s3, 1            # counter_tmp = counter + 1 
            div $t0, $s2                # added 1 to the mod calculate correctly
            mfhi $t1                    # (counter + 1) % num_columns
            li $t2, 0
            beq $t1, $t2, pmsi_print_bl  # if ((counter + 1) % num_columns == 0) print_bl
            
            # else print_space 
            pmsi_print_space:
            li $v0, 4
            la $a0, space
            syscall

            add $s0, $s0, $s4       # matrix_address += sizeof(int)    
            addi $s3, $s3, 1        # counter++
            j pmsi_loop

            pmsi_print_bl:
            li $v0, 4
            la $a0, bl
            syscall

            add $s0, $s0, $s4       # matrix_address++    
            addi $s3, $s3, 1        # counter++
            j pmsi_loop

        pmsi_end:
        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $s2, 8($sp)
        lw $s3, 12($sp)
        lw $s4, 16($sp)
        lw $ra, 20($sp)
        addi $sp, $sp, 24
        jr $ra
    # return: 

print_matrix_string_ascii:
    # args: $a0 - buffer, $a1 - sizeof(string)
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0           # matrix_address
    lw $s1, num_rows        # num_rows = num_rows
    lw $t0, num_columns     
    mul $s2, $t0, $a1       # num_columns = num_columns
    li $s3, 0               # counter
    move $s4, $a1           # sizeof(string)

    pmsa_loop:
        mul $t0, $s1, $s2           # last_pos = num_rows * num_columns   
        beq $s3, $t0, pmsa_end      # if (counter == last_pos) return
        lb $t0, 0($s0)              # matrix_address[counter]
        la $t1, char
        sb $t0, ($t1)
        # print char
        li $v0, 4
        la $a0, char
        syscall
        
        addi $t0, $s3, 1                # counter_tmp = counter + 1 
        div $t0, $s2                    # added 1 to the mod calculate correctly
        mfhi $t1                        # (counter + 1) % num_columns
        li $t2, 0
        beq $t1, $t2, pmsa_print_bl     # if ((counter + 1) % num_columns == 0) print_bl

        addi $t0, $s3, 1                # counter_tmp = counter + 1 
        div $t0, $s4 
        mfhi $t1                        # (counter + 1) % sizeof(string)
        li $t2, 0
        beq $t1, $t2, pmsa_print_space  # if ((counter + 1) % sizeof(string) == 0) print_space
        
        j pmsa_increment # else continue 
        
        pmsa_print_space:
        li $v0, 4
        la $a0, space
        syscall
        j pmsa_increment
        pmsa_print_bl:
        li $v0, 4
        la $a0, bl
        syscall
        j pmsa_increment

        pmsa_increment:
        addi $s0, $s0, 1        # matrix_address++    
        addi $s3, $s3, 1        # counter++
        j pmsa_loop

    pmsa_end:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return:

convert_int_to_string:
    # args: $a0 - value, $a1 - str length
    addi $sp, $sp, -28	# 7 register * 4 bytes = 28 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $s3, 12($sp)
    sw  $s4, 16($sp)
    sw  $s5, 20($sp)
    sw  $ra, 24($sp)

    move $s0, $a0       # int value
    move $s4, $a1       # str_length

    # create buffer
    li $v0, 9
    move $a0, $s4       # str length 
    syscall

    move $s1, $v0       # buffer_address
    move $s2, $v0       # buffer_address_tmp
    li $s3, 0           # last_digit
    li $s5, 0           # counter

    li $s4, 0                       # str_length = 0 -> we are going to count

    cits_zero_the_buffer_loop:
        beq $s5, $s3, cits_loop     # if (counter == str_length) break

        move $a0, $s1
        li $a1, 0
        move $a2, $s5
        jal replace_char_str        # replace(buffer, val, pos) 
        addi $s5, $s5, 1            # counter++

    j cits_zero_the_buffer_loop

    cits_loop:
        li $t0, 10
        div $s0, $t0                # value / 10
        # taking off the last_digit of the value and using it to the if statement
        mflo $s0                    # value / 10 result
        mfhi $s3                    # value % 10

        move $a0, $s2               # buffer_address_tmp
        addi $t0, $s3, 48           # converting the last_digit to char
        move $a1, $t0
        li $a2, 0
        jal replace_char_str        # replace(buffer, val, pos) 

        addi $s2, $s2, 1            # buffer_address_tmp++
        addi $s4, $s4, 1            # str_length++

        li $t2, 0                   # 0
        beq $s0, $t2, cits_exit     # if ((int)(value / 10) == 0) break 

        j cits_loop

    cits_exit:
    move $a0, $s1
    move $a1, $s4
    jal invert_str
    # move $v0, $v0
    
    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $s5, 20($sp)
    lw  $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra
    # return: $v0 - buffer_address

replace_char_str:
    # args: $a0 - buffer, $a1 - value, $a2 - pos
    addi $sp, $sp, -12	# 3 register * 4 bytes = 12 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $ra, 8($sp)

    move $s0, $a0       # tmp for buffer 
    li $s1, 0           # counter

    rcs_loop:
        beq $s1, $a2, rcs_replacement
        addi $s0, $s0, 1    # tmp++
        addi $s1, $s1, 1    # counter++
        j rcs_loop

    rcs_replacement:
    sb $a1, ($s0)

    rcs_exit:
    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

invert_str:
    # args: $a0 - buffer, $a1 - size
    addi $sp, $sp, -16	# 4 register * 4 bytes = 16 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $ra, 12($sp)

    move $s0, $a0       # old_buffer_tmp 
    li $s1, 0           # new_buffer
    move $s2, $a1       # str_length / new_buffer_pos

    # create buffer
    li $v0, 9
    move $a0, $s2       # str_length 
    syscall
    move $s1, $v0       # new_buffer

    addi $s2, $s2, -1   # positions in arrays begin in 0, so we sub 1

    is_loop:
        li $t0, 0
        blt $s2, $t0, is_exit       # if (new_buffer_pos < 0) break

        move $a0, $s1               # new_buffer_address
        lb $t0, ($s0)               # old_buffer_tmp
        move $a1, $t0
        
        move $a2, $s2               # new_buffer_pos                   
        jal replace_char_str        # replace(buffer, val, pos)

        addi $s0, $s0, 1            # old_buffer_tmp++
        addi $s2, $s2, -1           # new_buffer_pos--
        j is_loop


    is_exit:
    move $v0, $s1                   # new_buffer

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    # return: $v0 - new buffer address

matrix_int_to_matrix_string:
    # args: $a0 - matrix_int_address
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    move $s0, $a0           # matrix_int_address
    jal create_matrix_string
    move $s1, $v0           # matrix_string_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1       # matrix_length
    li $s3, 0               # counter

    mitms_loop:
        beq $s3, $s2, mitms_exit    # if (counter == matrix_length) break
        bgt $s3, $s2, mitms_exit    # if (counter > matrix_length) break

        # pos_matrix_int = matrix_int_address + (counter * sizeof(int)) 
        li $t0, 4
        mul $t1, $s3, $t0
        add $t1, $t1, $s0           

        lw $a0, 0($t1)
        jal get_int_length
        lw $a0, 0($t1)              # pos_matrix_int
        move $a1, $v0               # int_length
        jal convert_int_to_string
        move $t0, $v0               # converted_string

        # pos_matrix_string = matrix_string_address + (counter * sizeof(string)) 
        lw $t1, maximum_valmax_length   # sizeof(string)
        mul $t2, $s3, $t1
        add $t2, $t2, $s1

        # sw $t0, ($t2)                   # matrix_string[counter] = matrix_int[counter]  
        lb $t1, 0($t0)
        sb $t1, 0($t2)
        lb $t1, 1($t0)
        sb $t1, 1($t2)
        lb $t1, 2($t0)
        sb $t1, 2($t2)
        lb $t1, 3($t0)
        sb $t1, 3($t2)
        lb $t1, 4($t0)
        sb $t1, 4($t2)


        addi $s3, $s3, 1                # counter++

        j mitms_loop


    mitms_exit:
    move $v0, $s1

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return: $v0 - matrix_int_address

matrix_string_to_matrix_int:
    # args: $a0 - matrix_string_address
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    move $s0, $a0           # matrix_string_address
    jal create_matrix_int
    move $s1, $v0           # matrix_int_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1       # matrix_length
    li $s3, 0               # counter

    mstmi_loop:
        beq $s3, $s2, mstmi_exit    # if (counter == matrix_length) break
        bgt $s3, $s2, mstmi_exit    # if (counter > matrix_length) break

        # pos_matrix_string = matrix_string_address + (counter * sizeof(string)) 
        lw $t0, maximum_valmax_length
        mul $t1, $s3, $t0
        add $t1, $t1, $s0           

        move $a0, $t1               # pos_matrix_string
        lw $a1, maximum_valmax_length
        jal convert_string_to_int
        move $t0, $v0               # converted_value

        # pos_matrix_int = matrix_int_address + (counter * sizeof(int)) 
        li $t1, 4                   # sizeof(int)
        mul $t2, $s3, $t1
        add $t2, $t2, $s1

        sw $t0, ($t2)               # matrix_int[counter] = matrix_string[counter]  

        addi $s3, $s3, 1            # counter++

        j mstmi_loop


    mstmi_exit:
    move $v0, $s1

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return: $v0 - matrix_int_address