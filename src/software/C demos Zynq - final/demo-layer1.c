/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include <xparameters.h>
#include <xgpio.h>
#include <xbram.h>
#include "fixed_point_manipulation.h"
#include "cnn_utils.h"
//#include "example_face2.h"
#include "example_face2_padded.h"
#include "example_face2_nopadded.h"
#include "cnn_constants.h"
#include "cnn_constants_4_8.h"
#include "string.h"
#include "sys/time.h"
#include "sys/types.h"
#include "string.h"
#include "stdlib.h"
#include <xtime_l.h>

#define IMG_BRAM_SIZE_BYTES 65536
#define KERNEL_BRAM_SIZE_BYTES 524288

#define IMG_BRAM_SIZE_CELLS 3600
#define KERNEL_BRAM_SIZE_CELLS 7110

// from Excel bram structure, addresses in kernel BRAM
#define W1_BRAM_BASE_ADDR 0
#define W2_BRAM_BASE_ADDR 64
#define W3_BRAM_BASE_ADDR 1472
#define W4_BRAM_BASE_ADDR 2880
#define W5_BRAM_BASE_ADDR 4288
#define W6_BRAM_BASE_ADDR 5695

#define B_CONSTANTS_OFFSET 7104

#define SINGLE_IMG_BYTE_ADDRESS_SPAN 729      // 12bits*6pix*81rows/8
#define IMG_ADDR_DISTANCE 81
#define IMG_SECTOR2_ADDR_OFFSET 1782

XBram_Config *BramImg_cfg[6];
XBram_Config *BramKer_cfg;

XBram BramImg[6];
XBram BramKer;

double convolved1[22][48][48]; //[img_nr][W][H]
double convolved2[22][48][48];
double convolved2_p[22][24][24];
double convolved3[22][24][24];
double convolved4[22][24][24];
double convolved4_p1[22][12][12];
double convolved4_p2[22][6][6];
double convolved5[22][6][6];
double convolved6[22][6][6];

double convolved_acc[22][54][54]; //[img_nr][W][H]

void init_BRAMs(void) {

	BramImg_cfg[0] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_0_DEVICE_ID);
	BramImg_cfg[1] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_1_DEVICE_ID);
	BramImg_cfg[2] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_2_DEVICE_ID);
	BramImg_cfg[3] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_3_DEVICE_ID);
	BramImg_cfg[4] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_4_DEVICE_ID);
	BramImg_cfg[5] = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_5_DEVICE_ID);
	BramKer_cfg = XBram_LookupConfig(XPAR_AXI_BRAM_CTRL_6_DEVICE_ID);

	for (int j = 0; j < 6; j++) {
		XBram_CfgInitialize(&BramImg[j], BramImg_cfg[j],
				BramImg_cfg[j]->MemBaseAddress);
	}
	XBram_CfgInitialize(&BramKer, BramKer_cfg, BramKer_cfg->MemBaseAddress);
}

//reads 512 bits of single BRAM kernel cell and puts it as a hex string in outstr
void read_singlecell_ker_str(int cell_nr, char* outstr) {

	char tempstr[9];
	outstr[0] = '\0';

	int data_to_save = 0;

	for (int i = 0; i < 16; i++) { // writing 512 bit cell
		data_to_save = XBram_ReadReg(BramKer.Config.MemBaseAddress,
				(64 * cell_nr) + (4 * (15 - i)));
		sprintf(tempstr, "%08x", data_to_save);
		strcat(outstr, tempstr);

	}

}

//writes 512 bits of single BRAM kernel cell, instr needs to be 128 chars string , each char represent 4 bits
void write_singlecell_ker_str(int cell_nr, char* instr) {

	char tempstr[9];

	int data_to_save = 0;

	for (int i = 0; i < 16; i++) { // writing 512 bit cell
		tempstr[8] = '\0';
		strncpy(tempstr, &instr[8 * i], 8); // copy 8 characters from the stream
		sscanf(tempstr, "%x", &data_to_save);
		XBram_WriteReg(BramKer.Config.MemBaseAddress,
				(64 * cell_nr) + (4 * (15 - i)), data_to_save);

	}

}

//writes 128 bits of single BRAM kernel cell, instr needs to be 32 chars string , each char represent 4 bits
void write_singlecell_img_str(int bram_nr, int cell_nr, char* instr) {
	char tempstr[9];

	int data_to_save = 0;

	for (int i = 3; i >= 1; i--) { // writing 128 bit cell, !! ommiting first 32bit since they're not used !!
		tempstr[8] = '\0';
		strncpy(tempstr, &instr[8 * i], 8); // copy 8 characters from the stream
		sscanf(tempstr, "%x", &data_to_save);
		XBram_WriteReg(BramImg[bram_nr].Config.MemBaseAddress,
				(16 * cell_nr) + (4 * i), data_to_save);

	}
}

//reads 128 bits of single BRAM kernel cell and puts it as a hex string in outstr
void read_singlecell_img_str(int bram_nr, int cell_nr, char* outstr) {
	char tempstr[9];
	outstr[0] = '\0';

	int data_to_save = 0;

	for (int i = 0; i < 3; i++) { // writing 512 bit cell
		data_to_save = XBram_ReadReg(BramImg[bram_nr].Config.MemBaseAddress,
				(16 * cell_nr) + (4 * i));
		sprintf(tempstr, "%08x", data_to_save);
		strcat(outstr, tempstr);

	}

}

//reads 128(96) bits of single BRAM kernel cell and puts it in
//out_data byte array of 3 element each 32 bits (one element is avoided because of zero padding)
void read_singlecell_img_raw(int bram_nr, int cell_nr, u32* out_data) {
	for (int i = 0; i < 3; i++) { // reading 32 bit cell each
		out_data[i] = XBram_ReadReg(BramImg[bram_nr].Config.MemBaseAddress,
				(16 * cell_nr) + (4 * i));
	}
}

//writes 128(96) bits of single BRAM kernel cell from
//in_data array of 3 element each 32 bit (one element is avoided because of zero padding)
void write_singlecell_img_raw(int bram_nr, int cell_nr, u32* in_data) {
	for (int i = 0; i < 3; i++) { // writing 128 bit cell, !! ommiting first 32bit since they're not used !!
		XBram_WriteReg(BramImg[bram_nr].Config.MemBaseAddress,
				(16 * cell_nr) + (4 * i), in_data[i]);

	}
}

//writes 512 bits of single BRAM kernel cell from
//in_data array of 16 element each 32 bit
void write_singlecell_ker_raw(int cell_nr, u32* in_data) {
	for (int i = 0; i < 16; i++) { // writing 128 bit cell, !! ommiting first 32bit since they're not used !!
		XBram_WriteReg(BramKer.Config.MemBaseAddress, (64 * cell_nr) + (4 * i),
				in_data[i]);

	}
}

// quantises and saves Wc1- Wc6 and bc1-bc6 into the kernel BRAMs. run at the beggining, before accelerating.
void write_facial_cnn_kernels() {
	// saving Wc1
	char a[140]; //
	char tempstr[] = "000"; //0.001

	// 1D kernels (22x8x8)
	for (int ker_h = 0; ker_h < 8; ker_h++) {
		for (int ker_w = 0; ker_w < 8; ker_w++) {
			// reset the kernels
			tempstr[0] = '\0';
			a[0] = '\0';

			//put zeros at the beggining
			for (int i = 0; i < 62; i++) { // 512/4 - 22*3
				strcat(a, "0");
			}

			for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
				sprintf(tempstr, "%03x", toFixed_point(Wc1[i][ker_h][ker_w]));
				strcat(a, tempstr);
			}

			//finished the formation of the data string, send to the BRAM
			write_singlecell_ker_str(W1_BRAM_BASE_ADDR + (ker_h * 8) + ker_w,
					a);

		}
	}

	// 2D kernels 22x22x8x8
	for (int ker_depth = 0; ker_depth < 22; ker_depth++) {
		for (int ker_h = 0; ker_h < 8; ker_h++) {
			for (int ker_w = 0; ker_w < 8; ker_w++) {

				/////////////////////// W2 ////////////////
				// reset the kernels
				tempstr[0] = '\0';
				a[0] = '\0';

				//put zeros at the beggining
				for (int i = 0; i < 62; i++) { // 512/4 - 22*3
					strcat(a, "0");
				}

				for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
					sprintf(tempstr, "%03x",
							toFixed_point(Wc2[ker_depth][i][ker_h][ker_w]));
					strcat(a, tempstr);
				}

				//finished the formation of the data string, send to the BRAM
				write_singlecell_ker_str(
				W2_BRAM_BASE_ADDR + (64 * ker_depth) + (ker_h * 8) + ker_w, a);

				/////////////////////// W3 ////////////////
				// reset the kernels
				tempstr[0] = '\0';
				a[0] = '\0';

				//put zeros at the beggining
				for (int i = 0; i < 62; i++) { // 512/4 - 22*3
					strcat(a, "0");
				}

				for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
					sprintf(tempstr, "%03x",
							toFixed_point(Wc3[ker_depth][i][ker_h][ker_w]));
					strcat(a, tempstr);
				}

				//finished the formation of the data string, send to the BRAM
				write_singlecell_ker_str(
				W3_BRAM_BASE_ADDR + (64 * ker_depth) + (ker_h * 8) + ker_w, a);

				/////////////////////// W4 ////////////////
				// reset the kernels
				tempstr[0] = '\0';
				a[0] = '\0';

				//put zeros at the beggining
				for (int i = 0; i < 62; i++) { // 512/4 - 22*3
					strcat(a, "0");
				}

				for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
					sprintf(tempstr, "%03x",
							toFixed_point(Wc4[ker_depth][i][ker_h][ker_w]));
					strcat(a, tempstr);
				}

				//finished the formation of the data string, send to the BRAM
				write_singlecell_ker_str(
				W4_BRAM_BASE_ADDR + (64 * ker_depth) + (ker_h * 8) + ker_w, a);

				/////////////////////// W5 ////////////////
				// reset the kernels
				tempstr[0] = '\0';
				a[0] = '\0';

				//put zeros at the beggining
				for (int i = 0; i < 62; i++) { // 512/4 - 22*3
					strcat(a, "0");
				}

				for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
					sprintf(tempstr, "%03x",
							toFixed_point(Wc5[ker_depth][i][ker_h][ker_w]));
					strcat(a, tempstr);
				}

				//finished the formation of the data string, send to the BRAM
				write_singlecell_ker_str(
				W5_BRAM_BASE_ADDR + (64 * ker_depth) + (ker_h * 8) + ker_w, a);

				/////////////////////// W6 ////////////////
				// reset the kernels
				tempstr[0] = '\0';
				a[0] = '\0';

				//put zeros at the beggining
				for (int i = 0; i < 62; i++) { // 512/4 - 22*3
					strcat(a, "0");
				}

				for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
					sprintf(tempstr, "%03x",
							toFixed_point(Wc6[ker_depth][i][ker_h][ker_w]));
					strcat(a, tempstr);
				}

				//finished the formation of the data string, send to the BRAM
				write_singlecell_ker_str(
				W6_BRAM_BASE_ADDR + (64 * ker_depth) + (ker_h * 8) + ker_w, a);

			}
		}
	}

	/////////////////////// B constants for each layer ////////////////
	/////////////////////// L1
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc1[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 0, a);

	/////////////////////// L2
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc2[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 1, a);

	/////////////////////// L3
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc3[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 2, a);

	/////////////////////// L4
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc4[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 3, a);

	/////////////////////// L5
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc5[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 4, a);

	/////////////////////// L6
	// reset the kernels
	tempstr[0] = '\0';
	a[0] = '\0';

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		sprintf(tempstr, "%03x", toFixed_point(bc6[i]));
		strcat(a, tempstr);
	}

	//finished the formation of the data string, send to the BRAM
	write_singlecell_ker_str(
	B_CONSTANTS_OFFSET + 5, a);

}

//puts all kernel pixel values to 0.001
void write_example_ker() {

	char a[140]; //
	a[0] = '\0';
	char tempstr[] = "004"; //0.001

	//put zeros at the beggining
	for (int i = 0; i < 62; i++) { // 512/4 - 22*3
		strcat(a, "0");
	}

	for (int i = 21; i >= 0; i--) { // 22 kernels(3 chars each bc 12 bits) each cell
		//tempstr[2] = '0' + (i % 10);
		strcat(a, tempstr);
	}

	//finished the formation of the data string

	for (int j = 4096; j < 8192; j++) { // write to all addresses in the kernel cells
		// single cell write
		write_singlecell_ker_str(j, a);
	}

	// in the rest there are b constants, put zeros
	a[0] = '\0';
	for (int i = 0; i < 43; i++) { // 512/4 - 22*3
		strcat(a, "000");
	}
	for (int j = KERNEL_BRAM_SIZE_CELLS; j < (KERNEL_BRAM_SIZE_CELLS + 6);
			j++) { // write to all addresses in the kernel cells
		// single cell write
		//write_singlecell_ker_str(j, a);
	}
}

// for debugging the system, return 0 if ok, 1 if error
int test_RW_BRAM() {
	int error = 0;

	write_example_ker();
	char test[128];
	read_singlecell_ker_str(0, test);
	// if they're not the same then the test pattern
	if (strcmp(test,
			"00000000000000000000000000000000000000000000000000000000000000004004004004004004004004004004004004004004004004004004004004004004")) {
		error = 1;
	}

	double face_example_padded[54][54];
	double face_example_padded2[54][54];
	double zero_array[54][54];

	for (int i = 2; i < 51; i++) {
		for (int j = 2; j < 51; j++) {
			face_example_padded[i][j] = 0.153455 * (j % 6) + 0.5;
			zero_array[i][j] = 0.0;
		}
	}

	for (int k = 0; k < 44; k++) {
		save_image_img_bram(face_example_padded, k * IMG_ADDR_DISTANCE, 48);

		read_image_img_bram(face_example_padded2, k * IMG_ADDR_DISTANCE, 48);

		for (int i = 0; i < 51; i++) {
			for (int j = 0; j < 51; j++) {
				if (abs(face_example_padded[i][j] - face_example_padded2[i][j])
						> 0.001) {
					error = 1;
				}
			}
		}
		// saving back a zero value just in case
		save_image_img_bram(zero_array, k * IMG_ADDR_DISTANCE, 48);

	}
	return error;

}

// saved image into the first position in the BRAM to start the algorithm, img_length = 48, 24 or 6
void save_image_img_bram(double image[54][54], int cell_address_offset,
		int img_length) {

	// how long do we read ? depending on image size, 48 --> 9, 24 --> 5, 6-->2
	int max_it_imlen = (img_length + 6) / 6;

	u32 data_arr[3];
	for (int bram_nr = 0; bram_nr < 6; bram_nr++) {
		for (int j = 0; j < max_it_imlen; j++) {
			for (int i = 0; i < max_it_imlen; i++) {

				data_arr[0] = toFixed_point(image[6 * j + bram_nr][6 * i + 0])
						| (toFixed_point(image[6 * j + bram_nr][6 * i + 1])
								<< 12)
						| ((toFixed_point(image[6 * j + bram_nr][6 * i + 2])
								& 0x0FF) // 8 lsb
						<< 24);
				data_arr[1] = ((toFixed_point(image[6 * j + bram_nr][6 * i + 2])
						& 0xF00) >> 8) // 8 msb
				| (toFixed_point(image[6 * j + bram_nr][6 * i + 3]) << 4)
						| ((toFixed_point(image[6 * j + bram_nr][6 * i + 4]))
								<< 16)
						| ((toFixed_point(image[6 * j + bram_nr][6 * i + 5])
								& 0x00F) // 8 lsb
						<< 28);
				data_arr[2] = ((toFixed_point(image[6 * j + bram_nr][6 * i + 5])
						& 0xFF0) >> 4);
				write_singlecell_img_raw(bram_nr,
						i + (9 * j) + (cell_address_offset), data_arr);

			}
		}

	}

}

// saved image into the first position in the BRAM to start the algorithm , img_length = 48, 24 or 6
void read_image_img_bram(double *image, int cell_address_offset, int img_length) {

	// how long do we read ? depending on image size, 48 --> 9, 24 --> 5, 6-->2
	int max_it_imlen = (img_length + 6) / 6;

	u32 tmp_pix2;
	u32 temp_data[3];
	u32 tmp_pix5;
	for (int bram_nr = 0; bram_nr < 6; bram_nr++) {
		for (int j = 0; j < max_it_imlen; j++) {
			for (int i = 0; i < max_it_imlen; i++) {

				// reading the pixel BRAM
				read_singlecell_img_raw(bram_nr,
						i + (9 * j) + (cell_address_offset), temp_data);

				//pixel0
				image[((6 * j + bram_nr) * 54) + 6 * i + 0] = to_doubleVal(
						(temp_data[0] & 0x00000FFF) >> 0);

				//pixel1
				image[((6 * j + bram_nr) * 54) + 6 * i + 1] = to_doubleVal(
						(temp_data[0] & 0x00FFF000) >> 12);

				//pixel2 partly , LSB
				tmp_pix2 = (temp_data[0] & 0xFF000000) >> 24;

				//pixel2 partly , MSB
				image[((6 * j + bram_nr) * 54) + 6 * i + 2] = to_doubleVal(
						((temp_data[1] & 0x0000000F) << 8) | tmp_pix2);

				//pixel3
				image[((6 * j + bram_nr) * 54) + 6 * i + 3] = to_doubleVal(
						(temp_data[1] & 0x0000FFF0) >> 4);

				//pixel4
				image[((6 * j + bram_nr) * 54) + 6 * i + 4] = to_doubleVal(
						(temp_data[1] & 0x0FFF0000) >> 16);

				//pixel5 partly , LSB
				tmp_pix5 = (temp_data[1] & 0xF0000000) >> 28;

				//pixel5 partly , MSB
				image[((6 * j + bram_nr) * 54) + 6 * i + 5] = to_doubleVal(
						((temp_data[2] & 0x000000FF) << 4) | tmp_pix5);

			}
		}

	}

}

void start_accelerator(XGpio* command, int layer_nr) {
	u8 start_in = 3 << 1;
	u8 layer_nr_in = ((u8) layer_nr) << 3;

	// depending on GPIO Connections in Xilinx system block diagram
	XGpio_DiscreteWrite(command, 1, start_in | layer_nr_in);
	XGpio_DiscreteWrite(command, 1, layer_nr_in);
}

u8 check_accelerator_done(XGpio *status_gpio) {
	return XGpio_DiscreteRead(status_gpio, 1);
}

void reset_accelerator(XGpio *command) {

	u8 reset = 1 << 0;

	XGpio_DiscreteWrite(command, 1, reset);
	XGpio_DiscreteWrite(command, 1, 0);
}

void init_cnn_accelerator(XGpio *command, XGpio *status) {
	XGpio_Initialize(command, XPAR_AXI_GPIO_1_DEVICE_ID);
	XGpio_SetDataDirection(command, 1, 0x00); // set command as output ports

	XGpio_Initialize(status, XPAR_AXI_GPIO_2_DEVICE_ID);
	XGpio_SetDataDirection(status, 1, 0xFF); // set status as input ports

	XGpio_DiscreteWrite(command, 1, 0x00);

}

void profiler_accelerator_timings(XGpio command, XGpio status) {
	XTime t, temp;
	float layer_times[7] = { 0, 0, 0, 0, 0, 0, 0 };
	for (int j = 0; j < 10; j++) {
		for (int i = 1; i < 7; i++) {
			reset_accelerator(&command);

			start_accelerator(&command, i);

			while (check_accelerator_done(&status) == 0) {

			}
			XTime_GetTime(&t);
			start_accelerator(&command, i);

			while (check_accelerator_done(&status) == 0) {

			}

			XTime_GetTime(&temp);

			layer_times[i - 1] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;
		}
	}
}

void profiler_rec_with_acc_timings(double* in_face_img, XGpio* command,
		XGpio* status) {
	XTime t, temp;
	float layer_times[7] = { 0, 0, 0, 0, 0, 0, 0 };
	float transfer_times[7] = { 0, 0, 0, 0, 0, 0, 0 };
	double face_ex[54][54] = { 0 };

	for (int z = 0; z < 10; z++) {

		// put the single image into BRAM
		XTime_GetTime(&t);
		save_image_img_bram(in_face_img, 0, 48);
		XTime_GetTime(&temp);

		transfer_times[0] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		XTime_GetTime(&t);
		// START LAYER 1 CALC
		start_accelerator(command, 1);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[0] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// START LAYER 2 CALC
		XTime_GetTime(&t);
		start_accelerator(command, 2);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[1] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		//transfer_times[1] += 0; // no transfer time, because no max pooling

		//image transfer ACC BRAM --> proc. memory to do maxpooling
		XTime_GetTime(&t);
		for (int k = 0; k < 22; k++) { // read 22 full images
			read_image_img_bram(&face_ex[0][0], 0, 48);
			max_pool_2x2(&face_ex[0][0], 48, 48, face_ex);
		}
		XTime_GetTime(&temp);

		transfer_times[1] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		XTime_GetTime(&t);
		// write the maxpooled data back to BRAM
		for (int k = 0; k < 22; k++) { // write 4 times less data
			save_image_img_bram(face_ex, 0, 24);
		}
		XTime_GetTime(&temp);

		transfer_times[2] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// START LAYER 3 CALC
		XTime_GetTime(&t);
		start_accelerator(command, 3);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[2] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// START LAYER 4 CALC
		XTime_GetTime(&t);
		start_accelerator(command, 4);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[3] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		//image transfer ACC BRAM --> proc. memory to do maxpooling
		XTime_GetTime(&t);
		for (int i = 0; i < 22; i++) { // read 22 24x24 images
			read_image_img_bram(&face_ex[0][0], 0, 24);
			max_pool_2x2(face_ex, 24, 24, face_ex);
			max_pool_2x2(face_ex, 12, 12, face_ex);
		}
		XTime_GetTime(&temp);
		transfer_times[3] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		XTime_GetTime(&t);
		// saving the results
		for (int i = 0; i < 22; i++) { // save 22 6x6  images
			save_image_img_bram(&face_ex[0][0], 0, 6);
		}
		XTime_GetTime(&temp);

		transfer_times[4] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// START LAYER 5 CALC
		XTime_GetTime(&t);
		start_accelerator(command, 5);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[4] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// START LAYER 6 CALC
		XTime_GetTime(&t);
		start_accelerator(command, 6);
		while (check_accelerator_done(status) == 0)
			;

		XTime_GetTime(&temp);
		layer_times[5] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// Layer 7

		//transfer final imgs from bram to the proc memory
		XTime_GetTime(&t);
		for (int i = 0; i < 22; i++) { // read 22 6x6 images
			read_image_img_bram(face_ex, 0, 6);
		}
		XTime_GetTime(&temp);
		transfer_times[6] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

		// FULLY_CONNECTED LAYER - Matrix Multiplication
		XTime_GetTime(&t);
		float results[6] = { 0.0 };
		for (int nc = 0; nc < 6; nc++) {
			for (int i = 0; i < 22; i++) {
				for (int di = 0; di < 6; di++) {
					for (int dj = 0; dj < 6; dj++) {
						results[nc] += convolved6[i][di][dj]
								* Wn6[(36 * i) + (di * 6) + dj][nc];
					}
				}
			}
			results[nc] += bn6[nc]; // adding constant
		}

		SoftMax(&results[0], 6);
		XTime_GetTime(&temp);

		layer_times[6] += (temp - t) / ((float) COUNTS_PER_SECOND) / 10;

	}
}

void profile_rec_without_acceleration() {
	XTime t, temp, times_layers[10];
	int N = 1;

	XTime_GetTime(&t);

	float results[6];

	for (int k = 0; k < N; k++) {

		// LAYER 1
		for (int i = 0; i < 22; i++) {
			conv2d((const double *) &face2_no_padded[0][0], 48, 48,
					(double *) &Wc1_q[i][0][0], 8, 8,
					(double *) &convolved1[i][0][0]);
			add_const_((double *) &convolved1[i][0][0], 48, 48,
					(const double) bc1[i]);
			ReLU((double *) &convolved1[i][0][0], 48, 48);
		}

		XTime_GetTime(&temp);
		times_layers[0] = temp - t;
		XTime_GetTime(&t);

		//LAYER 2
		/*for (int i = 0; i < 22; i++) {
		 for (int j = 0; j < 22; j++) {
		 conv2d((const double *) &convolved1[j][0][0], 48, 48,
		 (double *) &Wc2[j][i][0][0], 8, 8,
		 (double *) &convolved2[i][0][0]);
		 }
		 max_pool_2x2((const double *) &convolved2[i][0][0], 48, 48,
		 (double *) &convolved2_p[i][0][0]);
		 add_const_((double *) &convolved2_p[i][0][0], 24, 24,
		 (const double) bc2[i]);
		 ReLU((double *) &convolved2_p[i][0][0], 24, 24);

		 }

		 XTime_GetTime(&temp);
		 times_layers[1] = temp - t;
		 XTime_GetTime(&t);
		 // convolution 2 fully validated.

		 // LAYER 3
		 for (int i = 0; i < 22; i++) {
		 for (int j = 0; j < 22; j++) {
		 conv2d((const double *) &convolved2_p[j][0][0], 24, 24,
		 (double *) &Wc3[j][i][0][0], 8, 8,
		 (double *) &convolved3[i][0][0]);
		 }
		 add_const_((double *) &convolved3[i][0][0], 24, 24,
		 (const double) bc3[i]);
		 ReLU((double *) &convolved3[i][0][0], 24, 24);
		 }

		 XTime_GetTime(&temp);
		 times_layers[2] = temp - t;
		 XTime_GetTime(&t);
		 // LAYER 4
		 for (int i = 0; i < 22; i++) {
		 for (int j = 0; j < 22; j++) {
		 conv2d((const double *) &convolved3[j][0][0], 24, 24,
		 (double *) &Wc4[j][i][0][0], 4, 4,
		 (double *) &convolved4[i][0][0]);
		 }
		 max_pool_2x2((const double *) &convolved4[i][0][0], 24, 24,
		 (double *) &convolved4_p1[i][0][0]);
		 max_pool_2x2((const double *) &convolved4_p1[i][0][0], 12, 12,
		 (double *) &convolved4_p2[i][0][0]);
		 add_const_((double *) &convolved4_p2[i][0][0], 6, 6,
		 (const double) bc4[i]);
		 ReLU((double *) &convolved4_p2[i][0][0], 6, 6);
		 }
		 XTime_GetTime(&temp);
		 times_layers[3] = temp - t;
		 XTime_GetTime(&t);

		 // LAYER 5
		 for (int i = 0; i < 22; i++) {
		 for (int j = 0; j < 22; j++) {
		 conv2d((const double *) &convolved4_p2[j][0][0], 6, 6,
		 (double *) &Wc5[j][i][0][0], 4, 4,
		 (double *) &convolved5[i][0][0]);
		 }
		 add_const_((double *) &convolved5[i][0][0], 6, 6,
		 (const double) bc5[i]);
		 ReLU((double *) &convolved5[i][0][0], 6, 6);
		 }
		 XTime_GetTime(&temp);
		 times_layers[4] = temp - t;
		 XTime_GetTime(&t);
		 // LAYER 6
		 for (int i = 0; i < 22; i++) {
		 for (int j = 0; j < 22; j++) {
		 conv2d((const double *) &convolved5[j][0][0], 6, 6,
		 (double *) &Wc6[j][i][0][0], 4, 4,
		 (double *) &convolved6[i][0][0]);
		 }
		 add_const_((double *) &convolved6[i][0][0], 6, 6,
		 (const double) bc6[i]);
		 ReLU((double *) &convolved6[i][0][0], 6, 6);
		 }
		 XTime_GetTime(&temp);
		 times_layers[5] = temp - t;
		 XTime_GetTime(&t);
		 // FULLY_CONNECTED LAYER - Matrix Multiplication
		 for (int nc = 0; nc < 6; nc++) {
		 for (int i = 0; i < 22; i++) {
		 for (int di = 0; di < 6; di++) {
		 for (int dj = 0; dj < 6; dj++) {
		 results[nc] += convolved6[i][di][dj]
		 * Wn6[(36 * i) + (di * 6) + dj][nc];
		 }
		 }
		 }
		 results[nc] += bn6[nc]; // adding constant
		 }
		 XTime_GetTime(&temp);
		 times_layers[6] = temp - t;
		 XTime_GetTime(&t);

		 SoftMax(&results[0], 6);
		 printf("\n");

		 }

		 double sum = 0;
		 for (int nc = 0; nc < 7; nc++) {
		 sum += ((float) times_layers[nc]) / COUNTS_PER_SECOND / N;
		 }

		 for (int nc = 0; nc < 7; nc++) {
		 printf("\n%d: %3.3f perc seconds ", nc,
		 100
		 * (((float) times_layers[nc]) / COUNTS_PER_SECOND / N
		 / sum));
		 }

		 printf("Average of clks to for the CNN algorithm : %u \n",
		 (unsigned int) t / N);
		 printf("Average execution time of the algorithm : %15f seconds \n",
		 ((float) t) / COUNTS_PER_SECOND / N);

		 printf("\n");

		 char emotions[6][6];
		 strcpy(emotions[0], "angry");
		 strcpy(emotions[1], "scared");
		 strcpy(emotions[2], "happy");
		 strcpy(emotions[3], "sad");
		 strcpy(emotions[4], "surpr");
		 strcpy(emotions[5], "normal");

		 // showing result as a graphical interface
		 for (int nc = 0; nc < 6; nc++) {
		 printf("%s \t %3.2f : ", emotions[nc], results[nc]);
		 for (double j = 0; j < 1.0; j += 0.04 / results[nc])
		 printf("+");
		 printf("\n");
		 }*/}
}

void zero_bram_memory(XBram bram) {
	UINTPTR *max_addr = (bram.Config.MemHighAddress);
	UINTPTR *base_addr = (bram.Config.MemBaseAddress);
	UINTPTR addr_span = max_addr - base_addr;
	for (UINTPTR i = 0; i < addr_span; i = i + 1) {
		XBram_WriteReg(base_addr, i, (u32 )0x00);
	}
}

int main() {

	XTime t, temp;

	init_platform();

	init_BRAMs();

	zero_bram_memory(BramImg[0]);
	zero_bram_memory(BramImg[1]);
	zero_bram_memory(BramImg[2]);
	zero_bram_memory(BramImg[3]);
	zero_bram_memory(BramImg[4]);
	zero_bram_memory(BramImg[5]);

	zero_bram_memory(BramKer);

	write_facial_cnn_kernels();

	XTime_GetTime(&t);
	profile_rec_without_acceleration(); // performed on face2, result is in a global variable "convolved1";
	XTime_GetTime(&temp);
	float wt_acc_exec_time = (temp - t) / (float) COUNTS_PER_SECOND;

	//write_example_ker();

	//Write to kernel BRAM manually
	/*u32 data_ker[21];
	 for (int i = 0; i < 7; i++) {
	 data_ker[3 * i] = 0x010008004;
	 data_ker[(3 * i) + 1] = 0;//0x40040040;
	 data_ker[(3 * i) + 2] = 0;//0x00400400;
	 }
	 for (int i = 0; i < 64; i++) {
	 write_singlecell_ker_raw(i, data_ker);
	 }*/

	XGpio command, status;
	init_cnn_accelerator(&command, &status);

	///test_RW_BRAM();

	//double face_example_padded[54][54];
	//double face_example_normal[48][48];
	//double img_software_result[48][48];
	//double face_acc_final_result[48][48];
	double img_accelerator_result[54][54];

	/*double kernel[8][8] = { 0.015625 }; // 2^-16 --> 004



	 for (int i = 0; i < 8; i++) {
	 for (int j = 0; j < 8; j++) {
	 kernel[i][j] = Wc1_q[Nr_img][i][j];
	 }
	 }

	 for (int i = 0; i < 54; i++) // zero padding
	 for (int j = 0; j < 54; j++)
	 face_example_padded[i][j] = 0.0;

	 for (int i = 3; i < 51; i++) {
	 for (int j = 3; j < 51; j++) {
	 face_example_padded[i][j] = ( 0.1 +  2.0/(i+2*j) ) ;
	 face_example_normal[i - 3][j - 3] = ( 0.1 +  2.0/(i+2*j));
	 }
	 }

	 // calculating the result to compare
	 conv2d((const double *) &face2_no_padded[0][0], 48, 48,
	 (double *) &kernel[0][0], 8, 8,
	 (double *) &img_software_result[0][0]);
	 add_const_( (const double *) &img_software_result[0][0], 48, 48,bc1[Nr_img]);
	 ReLU((const double *) &img_software_result[0][0], 48, 48);
	 */

	XTime_GetTime(&t);
	save_image_img_bram(face2_padded_zeros, 0 * IMG_ADDR_DISTANCE, 48);
	// START LAYER 1 CALC
	start_accelerator(&command, 1);
	while (check_accelerator_done(&status) == 0)
		;
	XTime_GetTime(&temp);
	float w_acc_exec_time = (temp - t) / (float) COUNTS_PER_SECOND;

	float acceleration = wt_acc_exec_time/w_acc_exec_time;
	double errors[22];

	// validating the results, reading images

	for (int Nr_img = 0; Nr_img < 22; Nr_img++) {
		errors[Nr_img] = 0;

		read_image_img_bram(img_accelerator_result,
				(Nr_img * IMG_ADDR_DISTANCE) + IMG_SECTOR2_ADDR_OFFSET, 48);
		for (int i = 3; i < 51; i++) {
			for (int j = 3; j < 51; j++) {
				if (((j - 3) % 6) < 3) {
					//face_acc_final_result[i - 3][j - 3] =
					//		img_accelerator_result[i][j+3];
					convolved_acc[Nr_img][i - 3][j - 3] =
							img_accelerator_result[i][j + 3];
				} else {
					//face_acc_final_result[i - 3][j - 3] =
					//					img_accelerator_result[i][j-3];
					convolved_acc[Nr_img][i - 3][j - 3] =
							img_accelerator_result[i][j - 3];
				}
				// calculating the error
				double pix_accelerated =  convolved_acc[Nr_img][i-3][j - 3];
				double pix_orig =  convolved1[Nr_img][i-3][j-3];

				errors[Nr_img]  += fabs( pix_orig-pix_accelerated );
			}
		}
		errors[Nr_img]  /= 2048;
	}

//profiler_rec_with_acc_timings(face_example_padded, &command, &status);

	cleanup_platform();
	return 0;
}
