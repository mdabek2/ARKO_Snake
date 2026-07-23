#------------------------------------------------------------
#			global
#------------------------------------------------------------
	.data
height:			.word 20
width:			.word 20
globals:		.word 7

empty:			.word 32	# ' '
top_bottom:		.word 95	# '_'
left_right:		.word 124	# '|'
fruit:			.word 36	# '$'
snake_body:		.word 42	# '*'

	.text

	lw  $t1, height
	lw  $t2, width

#----------------------space[5][5]---------------------------
	
	mul $a0, $t1, $t2
        sll $a0, $a0, 2	                    
	li  $v0, 9		#sbrk (allocate heap memory)
	syscall

	move $s0,$v0 		# save space address in $s0

#------------------isSnake[20][20]---------------------------

	mul $a0, $t1, $t2
	sll $a0, $a0, 2		
	li  $v0, 9 		#sbrk (allocate heap memory)
	syscall
	
	move $s1,$v0		# save isSnake address in $s1
	
#-------- heady, headx, taily, tailx, fruity, fruitx, length--

	lw $a0, globals
	sll $a0, $a0, 2		
	 
	li  $v0, 9 		#sbrk (allocate heap memory)
	syscall
	
	move $s2,$v0		# save globals' address in $s2
	
# heady - 0($s2)
# headx - 4($s2)
# taily - 8($s2)
# tailx - 12($s2)
# fruity - 16$s2)
# fruitx - 20($s2)
# length - 24($s2)



#------------------------------------------------------------
#			main()
#------------------------------------------------------------
	.data
g_over:	.asciiz	"\nGAME OVER\n"

# down:		115 's'
# right:	100 'd'	.
# left:		97  'a'
# up:		119 'w'
# esc:		101 'e'
	
	.text
main:
	addiu	$sp,$sp,-8	# allocate space for locals: bufx and bufy 
	
	j snake_set_start_board	# set start board	
after_start_board:

while:
	j snake_draw_board	# draw board
	
after_drawing:

	lw	$t1, 0($s2)	# bufy=heady
	sw	$t1, 4($sp)	
	
	lw	$t2, 4($s2)	# bufx=headx
	sw	$t2, 0($sp)	
	
	li	$v0, 12		# $v0 = read_character
	syscall	
	
case_s: 	
        bne 	$v0, 115, case_d  
        addi 	$t1, $t1, 1	# bufy++
	sw	$t1, 4($sp)
	j	end_switch
case_d: 	
        bne 	$v0, 100, case_w  
        addi 	$t2, $t2, 1	# bufx++
	sw	$t2, 0($sp)
	j	end_switch
case_w: 	
        bne 	$v0, 119, case_a  
        addi 	$t1, $t1, -1	# bufy--
	sw	$t1, 4($sp)
	j	end_switch
case_a: 	
        bne 	$v0, 97, case_e  
        addi 	$t2, $t2, -1	# bufx--
        sw	$t2, 0($sp)
        j	end_switch
case_e: 	
        bne 	$v0, 101, exit  
        j 	exit                   

end_switch:

#-------------check if snake's head is in bounds-------------

	addiu	$sp, $sp, -4	# allocate space for local: is
	jal	is_in_bounds   	# is_in_bounds(is, bufx, bufy)
	lw 	$t3, 0($sp)
	beqz	$t3, exit_1	# if is = 0, game over
	addiu	$sp, $sp, 4	# deallocate space for is

#--------------check if snake run into himself----------------	

	lw	$t1, 4($sp)	# $t1 = bufy
	lw	$t2, 0($sp)	# $t2 = bufx

	lw  	$t3, height
	lw  	$t4, width
	
	mul 	$t5, $t4, $t1	# $t5 <-- space address + (2^2 * (width * bufy + bufx))
	add 	$t5, $t5, $t2	# $t5 = adress of space[bufy][bufx]
	sll	$t5, $t5, 2    
	add 	$t5, $s0, $t5
	
	lw 	$t6, 0($t5)	
	lw 	$t7, snake_body
	 
	beq 	$t6, $t7, exit	# if space[bufy][bufx] == '*' exit
	
#---------------------moving snake forward--------------------
	
	jal	snake_move   	# snake_move(bufx, bufy)
	
#----------------end of while---------------------------------

	j while
	
exit:		
	addiu	$sp,$sp,8	# deallocate space for bufx and bufy
	li	$v0, 4		# print GAME OVER
	la	$a0, g_over	
	syscall
	
	li	$v0, 10		# end programme
	syscall

exit_1:
	addiu	$sp, $sp, 4	# deallocate space for is
	j exit

	
			
#------------------------------------------------------------
#		snake_set_start_board()
#------------------------------------------------------------
	.text
snake_set_start_board:

	addiu	$sp,$sp,-8			# allocate space for locals : new_y, new_x
	
	lw	$t1, height
	lw	$t2, width	

#-------------------fill with spaces--------------------------

blank_row_iter:
	li	$t3, 0               		# i=0
	
blank_column_iter:
	bge	$t3, $t1, blank_loop_end	# if i>=height go to end_loop
	li	$t4, 0              		# j=0
	
blank_inside_one_row:
	bge	$t4, $t2, blank_next_row	# if j>=width go to next_row

	mul	$t5, $t3, $t2 			# $t5 <-- base address + 4 * (width * i + j)
	add	$t5, $t5, $t4			# $t5 <-- adress of space[i][j]
	sll	$t5, $t5, 2         
	add	$t5, $s0, $t5       
    	
    	lw	$t6, empty
	sw	$t6,0($t5)			# adress of space[i][j] = ' ' 

	addi	$t4, $t4, 1			# j++

	b	blank_inside_one_row		# go to the next column

blank_next_row:
	addi	$t3, $t3, 1			# i++
	b	blank_column_iter		# go to the next row
    
blank_loop_end:

#--------------fill with left and right bounds----------------

left_right_row_iter:
	li	$t3, 1               		# i=1
	
left_right_inside_one_column:
	mul	$t4, $t3, $t2			# $t4 <-- base address + 4* (width * i + 0)
	sll	$t4, $t4, 2			# $t4 <-- adress of space[i][0]
	add	$t4, $s0, $t4      
	
	
	mul	$t5, $t3, $t2 			# $t5 <-- base address + 4*(width * i + width-1)
	add	$t5, $t5, $t2       		# $t5 <-- adress of space[i][width-1]
	addi	$t5, $t5, -1
	sll	$t5, $t5, 2       
	add	$t5, $s0, $t5
    	
    	lw	$t6, left_right
	sw	$t6,0($t4)          		# space[i][0] = '|'
	sw	$t6,0($t5)			# space[i][width-1] = '|'

	addi	$t3, $t3, 1			# i++
	
	bge	$t3, $t1, left_right_loop_end 	# if i>=height go to end_loop 
	
	j	left_right_inside_one_column	# go to the next row
    
left_right_loop_end:

#--------------fill with top and bottom bounds----------------

left_right_top_corner:
	li	$t4, 0				# $t4 <-- base address + 0
	add	$t4, $s0, $t4     		# $t4 <-- address of space[0][0]
	
	lw	$t6, top_bottom			
	sw	$t6, 0($t4)          		# space[0][0] = '_'
	
	lw 	$t4, width			# $t4 <-- base address + 4*(0 + width-1)
	addi 	$t4, $t4, -1			# $t4 <-- adress of space[0][width-1]
	sll 	$t4, $t4, 2         
	add 	$t4, $s0, $t4       
   
	lw	$t6, top_bottom
	sw	$t6, 0($t4)         		# space[0][width-1] = '_'
	
top_bottom_column_iter:
	li	$t3, 1         			# i=1
	
top_bottom_inside_one_row:
	li 	$t4, 0
	add	$t4, $t3, $t4       		# $t4 <-- base address + 4*(0 + i)
	sll 	$t4, $t4, 2         		# $t4 <-- space[0][i]
	add 	$t4, $s0, $t4       		
	
	addi	$t1, $t1, -1
	mul	$t5, $t2, $t1			# $t5 <-- base address + (width * (height-1) + i)
	add	$t5, $t5, $t3      		# $t5 <-- space[height-1][i]
	sll	$t5, $t5, 2        
	add	$t5, $s0, $t5      
    	addi	$t1, $t1, 1
    	
    	lw	$t6, top_bottom
	sw	$t6,0($t4)          		# space[0][i] = '|'
	sw	$t6,0($t5)          		# space[height-1][i] = '|'
	
	addiu	$t3, $t3, 1       		# i++
	
	addi	$t2, $t2, -1
	bge	$t3, $t2, top_bottom_loop_end 	# if i>=width-1 go to end_loop
	addi	$t2, $t2, 1
	
	j	top_bottom_inside_one_row	# go to the next column
    
top_bottom_loop_end:
	addi	$t2, $t2, 1
	
#--------------------fill with 5 star snake-------------------

	li	$t3, 3
	li	$t4, 3
	
	sw	$t3,4($sp)			# new_y = $t3 
	sw	$t4,0($sp)			# new_x = $t4
	
	jal	enqueue				# enqueue new head
		
	li	$t4, 4
	sw	$t4,0($sp)			# new_x = $t4
	
	jal	enqueue				# enqueue new head
	
	li	$t4, 5
	sw	$t4,0($sp)			# new_x = $t4
	
	jal	enqueue				# enqueue new head
	
	li	$t4, 6
	sw	$t4,0($sp)			# new_x = $t4
	
	jal	enqueue				# enqueue new head
	
	li	$t4, 7
	sw	$t4,0($sp)			# new_x = $t4
	
	jal	enqueue				# enqueue new head

#-----------------------fill with a fruit---------------------

while_fruit:
	li	$v0, 42        			# Service 42, random int smaller than 100
	li	$a1, 100          
	syscall					# Generate random int (returns in $a0)
	
	sb	$a0, 16($s2)			#  fruity = rand()
	sb	$a0, 20($s2)			#  fruitx = rand()
	
	lw	$t3, 16($s2)
	
	div	$t3, $t1
	mfhi	$t3				# $t3 = rand() % height
	
	sw	$t3, 16($s2)			# fruity = rand() % height
	
	lw	$t4, 20($s2)
	
	div	$t4, $t2
	mfhi	$t4 				# $t4 = rand() % width
	
	sw	$t4, 20($s2) 			# fruitx = rand() % width
	
	mul	$t5, $t2, $t3			# $t5 <-- base address + (width * fruity + fruitx)
	add	$t5, $t5, $t4       		# $t5 <-- adress of space[fruity][fruitx]
	sll	$t5, $t5, 2         
	add	$t5, $s0, $t5      
	
	lw	$t6, 0($t5)
	
	bne	$t6, 32, while_fruit		# if space[fruity][fruitx]!=' ' find new fruit
	
	lw	$t6, fruit
	sw	$t6, 0($t5) 			# space[fruity][fruitx]='$'

end_snake_strat_board:

	addiu	$sp,$sp,8			# deallocate space for parameters new_y, new_x
	j	after_start_board

		
#------------------------------------------------------------
#			snake_draw_board()
#------------------------------------------------------------
	.data
newLine:		.asciiz "\n"

	.text
       
snake_draw_board:

	lw	$t1, height
	lw 	$t2, width
	
	li	$v0, 4 
	la	$a0, newLine		#print NewLine
	syscall

draw_row_iter:
	li	$t3, 0			# i=0

draw_column_iter:
	bge	$t3, $t1, draw_end	# if i>=height to end drawing
	li	$t4, 0               	# j=0

draw_inside_one_row:
	bge	$t4, $t2, draw_next_row	# if j>=width go to the next row

	mul	$t5, $t3, $t2		# $t5 <-- base address + (2^2 * (width * i + j))
	add	$t5, $t5, $t4     	# $t5 <-- adress of space[i][j]
	sll	$t5, $t5, 2      
	add	$t5, $s0, $t5       
  
	
	li 	$v0, 4  
	la 	$a0, 0($t5)
	syscall
    
	li 	$v0, 4 
	la 	$a0, empty
	syscall

	addiu	$t4, $t4, 1      	# j++
	
	b 	draw_inside_one_row    	# go to the next column

draw_next_row:
	addiu	$t3, $t3, 1       	# i++
    
	li 	$v0, 4 
	la 	$a0, newLine
	syscall
    
	b	draw_column_iter	# go to the next row
	
draw_end:
	j after_drawing


#------------------------------------------------------------
#			snake_move()
#------------------------------------------------------------
	.text
snake_move:
	addiu	$sp,$sp,-4			# push $ra (2 instructions)
	sw	$ra,0($sp)
	addiu	$sp,$sp,-4			# push $fp (2 instructions)
	sw	$fp,0($sp)
	move	$fp, $sp			# set $fp
	
#---------------------adding head----------------------------

	addiu	$sp,$sp,-4			# allocate space for bufy
	lw 	$t1, 12($fp)
	sw	$t1, 0($sp)
	
	addiu	$sp,$sp,-4			# allocate space for bufx
	lw 	$t1, 8($fp)
	sw	$t1, 0($sp)
	
	jal 	enqueue				# enqueue head(bufy, bufx)
	
	addiu	$sp,$sp,8			# deallocate space for bufy, bufx

#-------------------check if eating fruit--------------------

	lw	$t1, 0($s2)			# $t1=heady
	lw	$t2, 4($s2)			# $t2=headx
	lw	$t3, 16($s2)			# $t3=fruity
	lw	$t4, 20($s2)			# $t4=fruitx
	
	bne	$t1, $t3, not_eating_fruit	# if heady!= taily
	bne	$t2, $t4, not_eating_fruit	# if headx!= tailx
	
	j	snake_set_fruit

not_eating_fruit:
	j	dequeue				# dequeue tail
	
return_move:
	move	$sp,$fp				
	lw	$fp,($sp)			# pop $fp (2 instructions)
	addiu	$sp,$sp,4
	lw	$ra,0($sp)			# pop $ra (2 instructions)
	addiu	$sp,$sp,4
	jr	$ra				# return
	
#------------------------------------------------------------
#		   snake_set_fruit()
#------------------------------------------------------------
	.text
	
snake_set_fruit:
	lw	$t1, height
	lw	$t2, width
	
while_set_fruit: 	
	li	$v0, 42			# Service 42, random int below 100
	li	$a1, 100        
	syscall           		# Generate random int (returns in $a0)
	
	sb	$a0, 16($s2)		#  fruity = rand()
	sb	$a0, 20($s2)		#  fruitx = rand()
	
	lw	$t3, 16($s2)
	
	div	$t3, $t1
	mfhi	$t3 			# $t3 = rand() % height
	
	sw $t3, 16($s2)			# fruity = rand() % height
	
	lw $t4, 20($s2)
	
	div $t4, $t2
	mfhi $t4 			# $t4 = rand() % width
	
	sw $t4, 20($s2) 		# fruitx = rand() % width
	
	mul $t5, $t2, $t3 		# $t5 <-- base address + (width * fruity + fruitx)
	add $t5, $t5, $t4       	# $t5 <-- space[fruity][fruitx]
	sll $t5, $t5, 2         
	add $t5, $s0, $t5       
	
	lw $t6, 0($t5)
	
	bne $t6, 32, while_set_fruit 	# if space[fruity][fruitx]!=' '
	
	lw $t6, fruit
	sw $t6, 0($t5) 			# space[fruity][fruitx]='$'
	
	j return_move

#------------------------------------------------------------
#		     is_in_bounds()
#------------------------------------------------------------
	.text
is_in_bounds:
	addiu	$sp,$sp,-4		# push $ra (2 instructions)
	sw	$ra,0($sp)
	addiu	$sp,$sp,-4		# push $fp (2 instructions)
	sw	$fp,0($sp)
	move	$fp,$sp			# set $fp
	
	
	lw 	$t1, height
	lw 	$t2, width
	addi	$t1, $t1, -1
	addi	$t2, $t2, -1
		
	lw	$t3, 16($fp)		# t3 = bufy
	lw	$t4, 12($fp)		# t4 = bufx
	
	blez 	$t3, set_not_true  	# if bufy<=0
	blez 	$t4, set_not_true   	# if bufx<=0
	
	slt 	$t5, $t3, $t1     	# if bufy<height-1
	beq 	$t5, 0, set_not_true     
	
	slt	$t5, $t4, $t2     	# if bufx<width-1
	beq 	$t5, 0, set_not_true     
	
set_true:
	li $t6, 1
	sw $t6, 8($fp)			#set is as 1
	j is_in_bounds_end
	
set_not_true:
	li $t6, 0
	sw $t6, 8($fp)			#set is as 0
	j is_in_bounds_end
	
is_in_bounds_end:
	move	$sp,$fp			
	lw	$fp,0($sp)		# pop $fp (2 instructions)
	addiu	$sp,$sp,4
	lw	$ra,0($sp)		# pop $ra (2 instructions)
	addiu	$sp,$sp,4
	jr	$ra			# return	
	
#------------------------------------------------------------
#			enqueue()
#------------------------------------------------------------	
	.text
enqueue:
	addiu	$sp,$sp,-4		# push $ra
	sw	$ra,0($sp)
	addiu	$sp,$sp,-4		# push $fp
	sw	$fp,0($sp)
	move	$fp,$sp			# set $fp
	
	
	lw  	$t1, height
	lw 	$t2, width
	
	lw	$t3, 8($fp)		# $t3 = x
	lw	$t4, 12($fp)		# $t4 = y
	
	lw	$t5, 24($s2)		# $t5 = length
	
	beq	$t5, $zero, beginning	# there is no snake yet
	
	lw	$t5, 24($s2)		# $t5 = length
	
	bnez 	$t5, continuation	# there is a snake
	
return_enqueue:

	sw	$t4, 0($s2)		# heady=y
	sw	$t3, 4($s2)		# headx=x
	
	mul	$t5, $t2, $t4		# $t5 <-- base address + (2^2 * (width * y + x))
	add	$t5, $t5, $t3       	# $t5 <-- adress of space[y][x]
	sll	$t5, $t5, 2         	
	add	$t5, $s0, $t5       	
	
	lw	$t6, snake_body		
	sw	$t6, 0($t5) 		# space[y][x] = '*'
	
	
	lw	$fp,($sp)		# pop $fp (2 instructions)
	addiu	$sp,$sp,4
	lw	$ra,0($sp)		# pop $ra (2 instructions)
	addiu	$sp,$sp,4
	jr	$ra			# return
	
	
beginning:
	mul	$t5, $t2, $t4		# $t5 <-- base address + (2^2 * (width * y + x))
	add	$t5, $t5, $t3		# $t5 <-- isSnake[y][x]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5      
	
	li	$t6, 1		
	sw	$t6, 0($t5)		# isSnake[y][x]=1
	sw	$t6, 24($s2)		# length=1
	
	sw	$t4, 8($s2) 		# taily=y
	sw	$t3, 12($s2)         	# tailx=x
	
	j	return_enqueue
	
continuation:
	lw	$t7, 0($s2)		# $t7 = heady
	
	mul	$t5, $t2, $t7		# $t5 <-- width * heady
	
	lw	$t7, 4($s2)		# $t7 = headx
	
	add	$t5, $t5, $t7       	# $t5 <-- width * heady + headx
	
	sll	$t5, $t5, 2         	# $t5 <-- base address + (2^2 * (width * heady + headx))
	add	$t5, $s1, $t5       	# $t5 <-- isSnake[heady][headx]
	
	lw 	$t6, 0($t5)		# $t6 = isSnake[heady][headx]
	addi 	$t6, $t6, 1		# $t6++
	
	mul	$t5, $t2, $t4 		# $t5 <-- base address + (2^2 * (width * y + x))
	add	$t5, $t5, $t3       	# $t5 <-- isSnake[y][x]
	sll	$t5, $t5, 2         	
	add	$t5, $s1, $t5       	
			
	sw 	$t6, 0($t5)		# isSnake[y][x]= isSnake[heady][headx]+1
	
	j return_enqueue


#------------------------------------------------------------
#			dequeue()
#------------------------------------------------------------
	.text
dequeue:
	lw	$t1, height
	lw	$t2, width
	lw	$t3, 8($s2) 	# $t3=taily
	lw	$t4, 12($s2)	# $t4=tailx
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of space[taily][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s0, $t5       
	
	lw	$t6, empty
	sw	$t6, 0($t5)	# space[taily][tailx] = ' ';
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	lw	$t6, 0($t5)	# $t6=isSnake[taily][tailx]
	
	addi	$t6, $t6, 1	# isSnake[taily][tailx]++

#---------------check if body is below tail------------------
	
down:
	addi	$t3, $t3, 1	#taily++
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * (taily+1) + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily+1][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	lw	$t7, 0($t5)	# $t7=isSnake[taily+1][tailx]
	
	addi	$t3, $t3, -1	#taily--
	
	beq	$t6, $t7, if_down	

#---------------check if body is above tail------------------

up:
	addi	$t3, $t3, -1	#taily--
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * (taily-1) + tailx))
	add	$t5, $t5, $t4	# $t5 <-- adress of isSnake[taily-1][tailx]
	sll	$t5, $t5, 2        
	add	$t5, $s1, $t5      
	
	lw	$t7, 0($t5)	# $t7=isSnake[taily-1][tailx]
	
	addi	$t3, $t3, 1	#taily++
	
	beq	$t6, $t7, if_up

#----------check if body is on the right of the tail---------

right:
	addi	$t4, $t4, 1	#tailx++
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * (taily) + tailx+1))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx+1]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	lw	$t7, 0($t5)	# $t7=isSnake[taily][tailx+1]
	
	addi	$t4, $t4, -1	#tailx--
	
	beq	$t6, $t7, if_right
	
#-----------check if body is on the left of the tail---------

left:
	addi	$t4, $t4, -1	#tailx--
	
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx-1))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx-1]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	lw	$t7, 0($t5)	# $t7=isSnake[taily][tailx-1]
	
	addi	$t4, $t4, 1	#tailx++
	
	beq	$t6, $t7, if_left

end_dequeue:
	j return_move
	

#------------------if body is below tail---------------------
if_down:
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4	# $t5 <-- adress of isSnake[taily][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	li	$t6, 0
	sw	$t6, 0($t5)	# isSnake[taily][tailx]=0
	
	addi	$t3, $t3, 1	#taily++
	sw	$t3, 8($s2)
	
	j	end_dequeue

#------------------if body is above tail---------------------
if_up:
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	li	$t6, 0
	sw	$t6, 0($t5)	# isSnake[taily][tailx]=0
	
	addi	$t3, $t3, -1	#taily--
	sw	$t3, 8($s2)
	
	j end_dequeue
	
#--------------if body is on the right of tail---------------

if_right:
	mul	$t5, $t2, $t3	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx]
	sll	$t5, $t5, 2         
	add	$t5, $s1, $t5       
	
	li	$t6, 0
	sw	$t6, 0($t5)	# isSnake[taily][tailx]=0
	
	addi	$t4, $t4, 1	# tailx++
	sw	$t4, 12($s2)
	
	j	end_dequeue
	
#--------------if body is on the let of tail-----------------

if_left:
	mul	$t5, $t2, $t3 	# $t5 <-- base address + (2^2 * (width * taily + tailx))
	add	$t5, $t5, $t4   # $t5 <-- adress of isSnake[taily][tailx]
	sll	$t5, $t5, 2     
	add	$t5, $s1, $t5    
	
	li	$t6, 0
	sw	$t6, 0($t5)	# isSnake[taily][tailx]=0
	
	addi	$t4, $t4, -1	# tailx--
	sw	$t4, 12($s2)
	
	j end_dequeue
