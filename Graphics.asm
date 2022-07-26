#Fall 2020 CSE12 Lab5 Template File

## Macro that stores the value in %reg on the stack 
##  and moves the stack pointer.
.macro push(%reg)
	subi $sp $sp 4
	sw %reg 0($sp)
.end_macro 

# Macro takes the value on the top of the stack and 
#  loads it into %reg then moves the stack pointer.
.macro pop(%reg)
	lw %reg 0($sp)
	addi $sp $sp 4	
.end_macro

# Macro that takes as input coordinates in the format
# (0x00XX00YY) and returns 0x000000XX in %x and 
# returns 0x000000YY in %y
.macro getCoordinates(%input %x %y)
	srl %x %input 16			#shift input right 4 words to get 0x000000XX
	
	andi %y %input 0x000000FF
	
	

.end_macro

# Macro that takes Coordinates in (%x,%y) where
# %x = 0x000000XX and %y= 0x000000YY and
# returns %output = (0x00XX00YY)
.macro formatCoordinates(%output %x %y)
	sll  %output %x 16			#shift x left 4 to get 0x00XX0000
	add %output %output %y			#add 0x00XX0000 with 0x000000YY

.end_macro 

#Macro that only gets the x coordinate from a pair of coordinates
.macro Xcoordinate(%output %x)
	srl %output %x 16

.end_macro

.data
originAddress: .word 0xFFFF0000

.text
j done
    
done: nop
	li $v0 10 
	syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
#Clear_bitmap: Given a color, will fill the bitmap display with that color.
#   Inputs:
#    $a0 = Color in format (0x00RRGGBB) 
#   Outputs:
#    No register outputs
#    Side-Effects: 
#    Colors the Bitmap display all the same color
#
#
#    Pseudo Code: I load the origin address
#		  then print the color at the address, after that i Increment address by
#	          4 to get to the next pixel untill it fills up the whole map.
#*****************************************************

clear_bitmap: nop
	lw $t0 originAddress
LoopOne:nop
	sw $a0 ($t0)
	addi $t0 $t0 4
     	beq  $t0 0xfffffffc ExitLoop1
	j  LoopOne
ExitLoop1:
	sw $a0 ($t0)	
 	jr $ra

#*****************************************************
# draw_pixel:
#  Given a coordinate in $a0, sets corresponding value
#  in memory to the color given by $a1	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of pixel in format (0x00XX00YY)
#    $a1 = color of pixel in format (0x00RRGGBB)
#   Outputs:
#    No register outputs
#
#	Pseudo Code: Load the origin address, then do ((y*128)+x)4
#	             Then add to origin address and print pixel. 
#*****************************************************
draw_pixel: nop
	getCoordinates($a0 $t2 $t3)		# getting x and y 
	lw $t0 originAddress			#loading origin into t0
	mul $t3 $t3 128				# using equation (y*128)
	add  $t4 $t3 $t2			# then (y*128) + x
	mul $t4 $t4 4				# then multiply ^ by 4 
	add $t0 $t0 $t4				# add value of top ^ into origin address
	sw $a1 ($t0)				# print color at address
	
	
	jr $ra
	
#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of pixel in format (0x00XX00YY)
#   Outputs:
#    Returns pixel color in $v0 in format (0x00RRGGBB)
#
#	Pseudo Code: load the origin address then do ((y*128)+x)4
#			then add the offset to origin and load the word into v0
#
#*****************************************************
get_pixel: nop
	getCoordinates($a0 $t2 $t3)
	lw $t0 originAddress			#loading origin into t0
	mul $t3 $t3 128				# using equation (y*128)
	add  $t4 $t3 $t2			# then (y*128) + x
	mul $t4 $t4 4				# then multiply ^ by 4 
	add $t0 $t0 $t4				# add value of top ^ into origin address
	lw  $v0 ($t0)				# print color at address

	jr $ra

#*****************************************************
#draw_rect: Draws a rectangle on the bitmap display.
#	Inputs:
#		$a0 = coordinates of top left pixel in format (0x00XX00YY)
#		$a1 = width and height of rectangle in format (0x00WW00HH)
#		$a2 = color in format (0x00RRGGBB) 
#	Outputs:
#		No register outputs
#
#		Pseudo Code: separate coords and rect dimensions
#				get the offset for the coordinate 
#				add that offset to the origin and then
#				start incrementing x by 4 untill I reach
#				x + width. Then i branch off and increment Y 
#				by 512 to go next line and reset my x to go
#				back to origin by subtracting the current
#				x with width*4. Print the color each time it 
#				loops
#*****************************************************
draw_rect: nop
	
	lw $t0 originAddress
	getCoordinates($a0 $t2 $t3)
	getCoordinates($a1 $t7 $t8)
	mul $t3 $t3 128				# using equation (y*128)
	add $t4 $t3 $t2			# then (y*128) + x
	mul $t4 $t4 4				# then multiply ^ by 4 
	add $t0 $t0 $t4				# add value of top ^ into origin address
	move $t5 $t0
	
	sw $a2 ($t0)
	
	add $t6 $t2 $t7
	
	add $t9 $t3 $t8
	subi $t9 $t9 1
	move $t4 $t2
	mul $t1 $t7 4
	
	
	
loop1:
	
	beq  $t2 $t6 IncreaseY
	sw $a2 ($t5)
	addi $t5 $t5 4			#increments after pritning so doesnt go over 1 
	addi $t2 $t2 1
	j loop1
IncreaseY:
	beq  $t3 $t9 exitloop
	sub $t5 $t5 $t1
	
	move $t2 $t4
	addi $t5 $t5 512
	addi $t3 $t3 1
	sw $a2 ($t5)
	
	j loop1
	
exitloop:
	
 	jr $ra

#***********************************************
# draw_diamond:
#  Draw diamond of given height peaking at given point.
#  Note: Assume given height is odd.
#-----------------------------------------------------
# draw_diamond(height, base_point_x, base_point_y)
# 	for (dy = 0; dy <= h; dy++)
# 		y = base_point_y + dy
#
# 		if dy <= h/2
# 			x_min = base_point_x - dy
# 			x_max = base_point_x + dy
# 		else
# 			x_min = base_point_x - floor(h/2) + (dy - ceil(h/2)) = base_point_x - h + dy
# 			x_max = base_point_x + floor(h/2) - (dy - ceil(h/2)) = base_point_x + h - dy
#
#   	for (x=x_min; x<=x_max; x++) 
# 			draw_diamond_pixels(x, y)
#-----------------------------------------------------
#   Inputs:
#    $a0 = coordinates of top point of diamond in format (0x00XX00YY)
#    $a1 = height of the diamond (must be odd integer)
#    $a2 = color in format (0x00RRGGBB)
#   Outputs:
#    No register outputs
#***************************************************
draw_diamond: nop
	push($s0)
	push($s1)
	move $t0 $a1
	getCoordinates($a0 $t1 $t2)
	li $t3 0
	div $t5 $t0 2 				#$t5 height/2
	lw $s0 originAddress
	
	
Diamond1:
	
	bgt $t3 $t0 End
	add $t4 $t2 $t3			#$t4 is y = base y + counter 
	
	blt $t3 $t5 Diamond2
	sub $t6 $t1 $t0
	add $t6 $t6 $t3
	add $t7 $t1 $t0
	sub $t7 $t7 $t3 		#MAX
	move $t8 $t6

cont:

					#x = xmin
	bgt $t6 $t7 add1		# branch if xmin bigger than x max
	
	mul $t8 $t4 128
	add $t8 $t8 $t6
	mul $t8 $t8 4
	add $s1 $s0 $t8
	sw $a2 ($s1)
	
	
	addi $t6 $t6 1
	
	j cont
	
add1: 
	addi $t3 $t3 1
	j Diamond1
	
	
	
Diamond2:
	sub $t6 $t1 $t3				#x min
	add $t7 $t1 $t3  			#x max 
	j cont
End:
	pop ($s1)
	pop($s0)
	jr $ra
	
