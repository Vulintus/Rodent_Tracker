function block_codes = Load_OmniTrak_File_Block_Codes(ver)

%LOAD_OMNITRAK_FILE_BLOCK_CODES.m
%
%	Vulintus, Inc.
%
%	OmniTrak file format block code libary.
%
%	Library V1 documentation:
%	https://docs.google.com/spreadsheets/d/e/2PACX-1vSt8EQXvF5DNkU8MrZYNL_1TcYMDagQc-U6WyK51xt2nk6oHyXr6Z0jQPUfQTLzla4QNMagKPDmxKJ0/pubhtml
%
%	This function was programmatically generated: 15-Mar-2022 09:52:43
%

block_codes = [];

switch ver

	case 1

		block_codes.CUR_DEF_VERSION = 1;

		block_codes.OMNITRAK_FILE_VERIFY = 43981;                           %First unsigned 16-bit integer written to every *.OmniTrak file to identify the file type, has a hex value of 0xABCD.

		block_codes.FILE_VERSION = 1;                                       %The version of the file format used.
		block_codes.MS_FILE_START = 2;                                      %Value of the SoC millisecond clock at file creation.
		block_codes.MS_FILE_STOP = 3;                                       %Value of the SoC millisecond clock when the file is closed.
		block_codes.SUBJECT_DEPRECATED = 4;                                 %A single subject's name.

		block_codes.CLOCK_FILE_START = 6;                                   %Computer clock serial date number at file creation (local time).
		block_codes.CLOCK_FILE_STOP = 7;                                    %Computer clock serial date number when the file is closed (local time).

		block_codes.DEVICE_FILE_INDEX = 10;                                 %The device's current file index.

		block_codes.NTP_SYNC = 20;                                          %A fetched NTP time (seconds since January 1, 1900) at the specified SoC millisecond clock time.
		block_codes.NTP_SYNC_FAIL = 21;                                     %Indicates the an NTP synchonization attempt failed.
		block_codes.MS_US_CLOCK_SYNC = 22;                                  %The current SoC microsecond clock time at the specified SoC millisecond clock time.
		block_codes.MS_TIMER_ROLLOVER = 23;                                 %Indicates that the millisecond timer rolled over since the last loop.
		block_codes.US_TIMER_ROLLOVER = 24;                                 %Indicates that the microsecond timer rolled over since the last loop.
		block_codes.TIME_ZONE_OFFSET = 25;                                  %Computer clock time zone offset from UTC.

		block_codes.RTC_STRING_DEPRECATED = 30;                             %Current date/time string from the real-time clock.
		block_codes.RTC_STRING = 31;                                        %Current date/time string from the real-time clock.
		block_codes.RTC_VALUES = 32;                                        %Current date/time values from the real-time clock.

		block_codes.ORIGINAL_FILENAME = 40;                                 %The original filename for the data file.
		block_codes.RENAMED_FILE = 41;                                      %A timestamped event to indicate when a file has been renamed by one of Vulintus' automatic data organizing programs.
		block_codes.DOWNLOAD_TIME = 42;                                     %A timestamp indicating when the data file was downloaded from the OmniTrak device to a computer.
		block_codes.DOWNLOAD_SYSTEM = 43;                                   %The computer system name and the COM port used to download the data file form the OmniTrak device.

		block_codes.INCOMPLETE_BLOCK = 50;                                  %Indicates that the file will end in an incomplete block.

		block_codes.USER_TIME = 60;                                         %Date/time values from a user-set timestamp.

		block_codes.SYSTEM_TYPE = 100;                                      %Vulintus system ID code (1 = MotoTrak, 2 = OmniTrak, 3 = HabiTrak, 4 = OmniHome, 5 = SensiTrak, 6 = Prototype).
		block_codes.SYSTEM_NAME = 101;                                      %System name.
		block_codes.SYSTEM_HW_VER = 102;                                    %Vulintus system hardware version.
		block_codes.SYSTEM_FW_VER = 103;                                    %System firmware version, written as characters.
		block_codes.SYSTEM_SN = 104;                                        %System serial number, written as characters.
		block_codes.SYSTEM_MFR = 105;                                       %Manufacturer name for non-Vulintus systems.
		block_codes.COMPUTER_NAME = 106;                                    %Windows PC computer name.
		block_codes.COM_PORT = 107;                                         %The COM port of a computer-connected system.

		block_codes.PRIMARY_MODULE = 110;                                   %Primary module name, for systems with interchangeable modules.
		block_codes.PRIMARY_INPUT = 111;                                    %Primary input name, for modules with multiple input signals.
        block_codes.SAMD_CHIP_ID = 112;                                     %The SAMD manufacturer's unique chip identifier.

		block_codes.ESP8266_MAC_ADDR = 120;                                 %The MAC address of the device's ESP8266 module.
		block_codes.ESP8266_IP4_ADDR = 121;                                 %The local IPv4 address of the device's ESP8266 module.
		block_codes.ESP8266_CHIP_ID = 122;                                  %The ESP8266 manufacturer's unique chip identifier
		block_codes.ESP8266_FLASH_ID = 123;                                 %The ESP8266 flash chip's unique chip identifier

		block_codes.USER_SYSTEM_NAME = 130;                                 %The user's name for the system, i.e. booth number.

		block_codes.DEVICE_RESET_COUNT = 140;                               %The current reboot count saved in EEPROM or flash memory.
		block_codes.CTRL_FW_FILENAME = 141;                                 %Controller firmware filename, copied from the macro, written as characters.
		block_codes.CTRL_FW_DATE = 142;                                     %Controller firmware upload date, copied from the macro, written as characters.
		block_codes.CTRL_FW_TIME = 143;                                     %Controller firmware upload time, copied from the macro, written as characters.
		block_codes.MODULE_FW_FILENAME = 144;                               %OTMP Module firmware filename, copied from the macro, written as characters.
		block_codes.MODULE_FW_DATE = 145;                                   %OTMP Module firmware upload date, copied from the macro, written as characters.
		block_codes.MODULE_FW_TIME = 146;                                   %OTMP Module firmware upload time, copied from the macro, written as characters.

		block_codes.WINC1500_MAC_ADDR = 150;                                %The MAC address of the device's ATWINC1500 module.
		block_codes.WINC1500_IP4_ADDR = 151;                                %The local IPv4 address of the device's ATWINC1500 module.

		block_codes.BATTERY_SOC = 170;                                      %Current battery state-of charge, in percent, measured the BQ27441
		block_codes.BATTERY_VOLTS = 171;                                    %Current battery voltage, in millivolts, measured by the BQ27441
		block_codes.BATTERY_CURRENT = 172;                                  %Average current draw from the battery, in milli-amps, measured by the BQ27441
		block_codes.BATTERY_FULL = 173;                                     %Full capacity of the battery, in milli-amp hours, measured by the BQ27441
		block_codes.BATTERY_REMAIN = 174;                                   %Remaining capacity of the battery, in milli-amp hours, measured by the BQ27441
		block_codes.BATTERY_POWER = 175;                                    %Average power draw, in milliWatts, measured by the BQ27441
		block_codes.BATTERY_SOH = 176;                                      %Battery state-of-health, in percent, measured by the BQ27441
		block_codes.BATTERY_STATUS = 177;                                   %Combined battery state-of-charge, voltage, current, capacity, power, and state-of-health, measured by the BQ27441

		block_codes.FEED_SERVO_MAX_RPM = 190;                               %Actual rotation rate, in RPM, of the feeder servo (OmniHome) when set to 180 speed.
		block_codes.FEED_SERVO_SPEED = 191;                                 %Current speed setting (0-180) for the feeder servo (OmniHome).

		block_codes.SUBJECT_NAME = 200;                                     %A single subject's name.
		block_codes.GROUP_NAME = 201;                                       %The subject's or subjects' experimental group name.

		block_codes.EXP_NAME = 300;                                         %The user's name for the current experiment.
		block_codes.TASK_TYPE = 301;                                        %The user's name for task type, which can be a variant of the overall experiment type.

		block_codes.STAGE_NAME = 400;                                       %The stage name for a behavioral session.
		block_codes.STAGE_DESCRIPTION = 401;                                %The stage description for a behavioral session.

		block_codes.AMG8833_ENABLED = 1000;                                 %Indicates that an AMG8833 thermopile array sensor is present in the system.
		block_codes.BMP280_ENABLED = 1001;                                  %Indicates that an BMP280 temperature/pressure sensor is present in the system.
		block_codes.BME280_ENABLED = 1002;                                  %Indicates that an BME280 temperature/pressure/humidty sensor is present in the system.
		block_codes.BME680_ENABLED = 1003;                                  %Indicates that an BME680 temperature/pressure/humidy/VOC sensor is present in the system.
		block_codes.CCS811_ENABLED = 1004;                                  %Indicates that an CCS811 VOC/eC02 sensor is present in the system.
		block_codes.SGP30_ENABLED = 1005;                                   %Indicates that an SGP30 VOC/eC02 sensor is present in the system.
		block_codes.VL53L0X_ENABLED = 1006;                                 %Indicates that an VL53L0X time-of-flight distance sensor is present in the system.
		block_codes.ALSPT19_ENABLED = 1007;                                 %Indicates that an ALS-PT19 ambient light sensor is present in the system.
		block_codes.MLX90640_ENABLED = 1008;                                %Indicates that an MLX90640 thermopile array sensor is present in the system.
		block_codes.ZMOD4410_ENABLED = 1009;                                %Indicates that an ZMOD4410 VOC/eC02 sensor is present in the system.

		block_codes.AMG8833_THERM_CONV = 1100;                              %The conversion factor, in degrees Celsius, for converting 16-bit integer AMG8833 pixel readings to temperature.
		block_codes.AMG8833_THERM_FL = 1101;                                %The current AMG8833 thermistor reading as a converted float32 value, in Celsius.
		block_codes.AMG8833_THERM_INT = 1102;                               %The current AMG8833 thermistor reading as a raw, signed 16-bit integer.

		block_codes.AMG8833_PIXELS_CONV = 1110;                             %The conversion factor, in degrees Celsius, for converting 16-bit integer AMG8833 pixel readings to temperature.
		block_codes.AMG8833_PIXELS_FL = 1111;                               %The current AMG8833 pixel readings as converted float32 values, in Celsius.
		block_codes.AMG8833_PIXELS_INT = 1112;                              %The current AMG8833 pixel readings as a raw, signed 16-bit integers.

		block_codes.BME280_TEMP_FL = 1200;                                  %The current BME280 temperature reading as a converted float32 value, in Celsius.
		block_codes.BMP280_TEMP_FL = 1201;                                  %The current BMP280 temperature reading as a converted float32 value, in Celsius.
		block_codes.BME680_TEMP_FL = 1202;                                  %The current BME680 temperature reading as a converted float32 value, in Celsius.

		block_codes.BME280_PRES_FL = 1210;                                  %The current BME280 pressure reading as a converted float32 value, in Pascals (Pa).
		block_codes.BMP280_PRES_FL = 1211;                                  %The current BMP280 pressure reading as a converted float32 value, in Pascals (Pa).
		block_codes.BME680_PRES_FL = 1212;                                  %The current BME680 pressure reading as a converted float32 value, in Pascals (Pa).

		block_codes.BME280_HUM_FL = 1220;                                   %The current BM280 humidity reading as a converted float32 value, in percent (%).

		block_codes.VL53L0X_DIST = 1300;                                    %The current VL53L0X distance reading as a 16-bit integer, in millimeters (-1 indicates out-of-range).
		block_codes.VL53L0X_FAIL = 1301;                                    %Indicates the VL53L0X sensor experienced a range failure.

		block_codes.SGP30_SN = 1400;                                        %The serial number of the SGP30.

		block_codes.SGP30_EC02 = 1410;                                      %The current SGp30 eCO2 reading distance reading as a 16-bit integer, in parts per million (ppm).

		block_codes.SGP30_TVOC = 1420;                                      %The current SGp30 TVOC reading distance reading as a 16-bit integer, in parts per million (ppm).

		block_codes.MLX90640_DEVICE_ID = 1500;                              %The MLX90640 unique device ID saved in the device's EEPROM.
		block_codes.MLX90640_EEPROM_DUMP = 1501;                            %Raw download of the entire MLX90640 EEPROM, as unsigned 16-bit integers.
		block_codes.MLX90640_ADC_RES = 1502;                                %ADC resolution setting on the MLX90640 (16-, 17-, 18-, or 19-bit).
		block_codes.MLX90640_REFRESH_RATE = 1503;                           %Current refresh rate on the MLX90640 (0.25, 0.5, 1, 2, 4, 8, 16, or 32 Hz).
		block_codes.MLX90640_I2C_CLOCKRATE = 1504;                          %Current I2C clock freqency used with the MLX90640 (100, 400, or 1000 kHz).

		block_codes.MLX90640_PIXELS_TO = 1510;                              %The current MLX90640 pixel readings as converted float32 values, in Celsius.
		block_codes.MLX90640_PIXELS_IM = 1511;                              %The current MLX90640 pixel readings as converted, but uncalibrationed, float32 values.
		block_codes.MLX90640_PIXELS_INT = 1512;                             %The current MLX90640 pixel readings as a raw, unsigned 16-bit integers.

		block_codes.MLX90640_I2C_TIME = 1520;                               %The I2C transfer time of the frame data from the MLX90640 to the microcontroller, in milliseconds.
		block_codes.MLX90640_CALC_TIME = 1521;                              %The calculation time for the uncalibrated or calibrated image captured by the MLX90640.
		block_codes.MLX90640_IM_WRITE_TIME = 1522;                          %The SD card write time for the MLX90640 float32 image data.
		block_codes.MLX90640_INT_WRITE_TIME = 1523;                         %The SD card write time for the MLX90640 raw uint16 data.

		block_codes.ALSPT19_LIGHT = 1600;                                   %The current analog value of the ALS-PT19 ambient light sensor, as an unsigned integer ADC value.

		block_codes.ZMOD4410_MOX_BOUND = 1700;                              %The current lower and upper bounds for the ZMOD4410 ADC reading used in calculations.
		block_codes.ZMOD4410_CONFIG_PARAMS = 1701;                          %Current configuration values for the ZMOD4410.
		block_codes.ZMOD4410_ERROR = 1702;                                  %Timestamped ZMOD4410 error event.
		block_codes.ZMOD4410_READING_FL = 1703;                             %Timestamped ZMOD4410 reading calibrated and converted to float32.
		block_codes.ZMOD4410_READING_INT = 1704;                            %Timestamped ZMOD4410 reading saved as the raw uint16 ADC value.

		block_codes.ZMOD4410_ECO2 = 1710;                                   %Timestamped ZMOD4410 eCO2 reading.
		block_codes.ZMOD4410_IAQ = 1711;                                    %Timestamped ZMOD4410 indoor air quality reading.
		block_codes.ZMOD4410_TVOC = 1712;                                   %Timestamped ZMOD4410 total volatile organic compound reading.
		block_codes.ZMOD4410_R_CDA = 1713;                                  %Timestamped ZMOD4410 total volatile organic compound reading.

		block_codes.LSM303_ACC_SETTINGS = 1800;                             %Current accelerometer reading settings on any enabled LSM303.
		block_codes.LSM303_MAG_SETTINGS = 1801;                             %Current magnetometer reading settings on any enabled LSM303.
		block_codes.LSM303_ACC_FL = 1802;                                   %Current readings from the LSM303 accelerometer, as float values in m/s^2.
		block_codes.LSM303_MAG_FL = 1803;                                   %Current readings from the LSM303 magnetometer, as float values in uT.

		block_codes.SPECTRO_WAVELEN = 1900;                                 %Spectrometer wavelengths, in nanometers.
		block_codes.SPECTRO_TRACE = 1901;                                   %Spectrometer measurement trace.

		block_codes.PELLET_DISPENSE = 2000;                                 %Timestamped event for feeding/pellet dispensing.
		block_codes.PELLET_FAILURE = 2001;                                  %Timestamped event for feeding/pellet dispensing in which no pellet was detected.

		block_codes.HARD_PAUSE_START = 2010;                                %Timestamped event marker for the start of a session pause, with no events recorded during the pause.
		block_codes.HARD_PAUSE_START = 2011;                                %Timestamped event marker for the stop of a session pause, with no events recorded during the pause.
		block_codes.SOFT_PAUSE_START = 2012;                                %Timestamped event marker for the start of a session pause, with non-operant events recorded during the pause.
		block_codes.SOFT_PAUSE_START = 2013;                                %Timestamped event marker for the stop of a session pause, with non-operant events recorded during the pause.

		block_codes.POSITION_START_X = 2020;                                %Starting position of an autopositioner in just the x-direction, with distance in millimeters.
		block_codes.POSITION_MOVE_X = 2021;                                 %Timestamped movement of an autopositioner in just the x-direction, with distance in millimeters.
		block_codes.POSITION_START_XY = 2022;                               %Starting position of an autopositioner in just the x- and y-directions, with distance in millimeters.
		block_codes.POSITION_MOVE_XY = 2023;                                %Timestamped movement of an autopositioner in just the x- and y-directions, with distance in millimeters.
		block_codes.POSITION_START_XYZ = 2024;                              %Starting position of an autopositioner in the x-, y-, and z- directions, with distance in millimeters.
		block_codes.POSITION_MOVE_XYZ = 2025;                               %Timestamped movement of an autopositioner in the x-, y-, and z- directions, with distance in millimeters.

		block_codes.STREAM_INPUT_NAME = 2100;                               %Stream input name for the specified input index.

		block_codes.CALIBRATION_BASELINE = 2200;                            %Starting calibration baseline coefficient, for the specified module index.
		block_codes.CALIBRATION_SLOPE = 2201;                               %Starting calibration slope coefficient, for the specified module index.
		block_codes.CALIBRATION_BASELINE_ADJUST = 2202;                     %Timestamped in-session calibration baseline coefficient adjustment, for the specified module index.
		block_codes.CALIBRATION_SLOPE_ADJUST = 2203;                        %Timestamped in-session calibration slope coefficient adjustment, for the specified module index.

		block_codes.HIT_THRESH_TYPE = 2300;                                 %Type of hit threshold (i.e. peak force), for the specified input.

		block_codes.SECONDARY_THRESH_NAME = 2310;                           %A name/description of secondary thresholds used in the behavior.

		block_codes.INIT_THRESH_TYPE = 2320;                                %Type of initation threshold (i.e. force or touch), for the specified input.

		block_codes.REMOTE_MANUAL_FEED = 2400;                              %A timestamped manual feed event, triggered remotely.
		block_codes.HWUI_MANUAL_FEED = 2401;                                %A timestamped manual feed event, triggered from the hardware user interface.
		block_codes.FW_RANDOM_FEED = 2402;                                  %A timestamped manual feed event, triggered randomly by the firmware.
		block_codes.SWUI_MANUAL_FEED_DEPRECATED = 2403;                     %A timestamped manual feed event, triggered from a computer software user interface.
		block_codes.FW_OPERANT_FEED = 2404;                                 %A timestamped operant-rewarded feed event, trigged by the OmniHome firmware, with the possibility of multiple feedings.
		block_codes.SWUI_MANUAL_FEED = 2405;                                %A timestamped manual feed event, triggered from a computer software user interface.
		block_codes.SW_RANDOM_FEED = 2406;                                  %A timestamped manual feed event, triggered randomly by computer software.
		block_codes.SW_OPERANT_FEED = 2407;                                 %A timestamped operant-rewarded feed event, trigged by the PC-based behavioral software, with the possibility of multiple feedings.

		block_codes.MOTOTRAK_V3P0_OUTCOME = 2500;                           %MotoTrak version 3.0 trial outcome data.
		block_codes.MOTOTRAK_V3P0_SIGNAL = 2501;                            %MotoTrak version 3.0 trial stream signal.

		block_codes.OUTPUT_TRIGGER_NAME = 2600;                             %Name/description of the output trigger type for the given index.

		block_codes.VIBRATION_TASK_TRIAL_OUTCOME = 2700;                    %Vibration task trial outcome data.

		block_codes.LED_DETECTION_TASK_TRIAL_OUTCOME = 2710;                %LED detection task trial outcome data.
		block_codes.LIGHT_SRC_MODEL = 2711;                                 %Light source model name.
		block_codes.LIGHT_SRC_TYPE = 2712;                                  %Light source type (i.e. LED, LASER, etc).

		block_codes.STTC_2AFC_TRIAL_OUTCOME = 2720;                         %SensiTrak tactile discrimination task trial outcome data.
		block_codes.STTC_NUM_PADS = 2721;                                   %Number of pads on the SensiTrak Tactile Carousel module.
		block_codes.MODULE_MICROSTEP = 2722;                                %Microstep setting on the specified OTMP module.
		block_codes.MODULE_STEPS_PER_ROT = 2723;                            %Steps per rotation on the specified OTMP module.

		block_codes.MODULE_PITCH_CIRC = 2730;                               %Pitch circumference, in millimeters, of the driving gear on the specified OTMP module.
		block_codes.MODULE_CENTER_OFFSET = 2731;                            %Center offset, in millimeters, for the specified OTMP module.

		block_codes.STAP_2AFC_TRIAL_OUTCOME = 2740;                         %SensiTrak proprioception discrimination task trial outcome data.

end
