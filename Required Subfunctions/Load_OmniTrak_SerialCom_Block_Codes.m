function block_codes = Load_OmniTrak_SerialCom_Block_Codes(ver)

%LOAD_OMNITRAK_SERIALCOM_BLOCK_CODES.m
%
%	Vulintus, Inc.
%
%	OmniTrak serial communication block code libary.
%
%	Library V1 documentation:
%	https://docs.google.com/spreadsheets/d/e/2PACX-1vSzmDjLhwK4nVf75wrWSNnuTfP9Wj78yEe8ppygF7yVZp6Bm3ORDl6wD1ffGRoQseNZRZCDsRRBymhU/pubhtml
%
%	This function was programmatically generated: 17-Feb-2021 13:56:43
%

block_codes = [];

switch ver

	case 1
		block_codes.CUR_DEF_VERSION = 1;

		block_codes.RESET = 0;
		block_codes.VERIFY = 1;
		block_codes.LIB_VER = 2;

		block_codes.SYSTEM_TYPE = 10;
		block_codes.SYSTEM_NAME = 11;
		block_codes.SYSTEM_HW_VER = 12;

		block_codes.COM_PORT = 20;
		block_codes.GET_MAC_ADDR = 21;

		block_codes.RTC_STRING = 30;
		block_codes.SET_RTC = 31;

		block_codes.SET_CUR_DIR = 81;
		block_codes.GET_CUR_DIR = 82;
		block_codes.REWIND_DIR = 83;
		block_codes.NEXT_FILE  = 84;
		block_codes.CUR_FILE_NAME = 85;
		block_codes.CUR_FILE_SIZE = 86;
		block_codes.CUR_FILE_ISDIR = 87;
		block_codes.REWIND_CUR_FILE = 88;
		block_codes.DUMP_FILE = 89;
		block_codes.DELETE_FILE = 90;
		block_codes.DELETE_DIR = 91;

end
