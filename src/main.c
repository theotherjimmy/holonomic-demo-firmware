#include <main.h>
#include <stddef.h>
#include <RASLib/inc/common.h>
#include <RASLib/inc/motor.h>
#include <RASLib/inc/gpio.h>
#include <RASLib/inc/time.h>
#include <RASLib/inc/timeout.h>
#include <RASLib/inc/uart.h>

tUART * uart5;
static int ledState = 0;

void ToggleLED (void) {
        SetPin(PIN_F1, ledState & 1);
        ++ledState;
}

static tMotor * motors[4];

void doMotorState (float x, float y, float w) {
        SetMotor(motors[0], - w - x - y);
        SetMotor(motors[1], - w - x + y);
        SetMotor(motors[2], - w + x + y);
        SetMotor(motors[3], - w + x - y);
}

void StopMotors (void * trash){
        trash = trash;
        doMotorState(0.0f,0.0f,0.0f);
        SetPin(PIN_F2, false);
}

int main (void) {
        int i = 0;
        InitializeSystemTimeout();
        int tid  = CallOnTimeout(StopMotors, NULL, 0.1f);
        uart5 = InitializeUARTModule(4, 115200);
        for (; i < 4; ++i) {
                motors[i] = InitializeServoMotor(i + PIN_D0, false);
        }
        doMotorState(0.0f,0.0f,0.0f);
        CallEvery(ToggleLED, 0, 0.5);
        //fPrintf(uart5, "$$$");
        //fScanf(uart5, "CMD\n\r");
        //Wait(0.1);
        //Printf("entered command mode\n");
        //fPrintf(uart5, "SM,0\r");
        //fScanf(uart5, "\rAOK\n\r");
        //Wait(0.1);
        //Printf("set master/slave mode\n");
        //fPrintf(uart5, "SN,Moses\r");
        //fScanf(uart5, "\rAOK\n\r");
        //Wait(0.1);
        //Printf("set names\n");
        //fPrintf(uart5, "---\r");
        //fScanf(uart5, "\rEND\n\r");
        //Wait(0.1);
        //Printf("Waiting for connection\n");
        //SetPin(PIN_F2, 1);
        /* Wait for conection from YahWeh */
        while (!(fKeyWasPressed(uart5) && fGetc(uart5) == 'Y'));
        Printf("Connected!");
        while (1) {
                float x, y, w;
                while (!fKeyWasPressed(uart5));
                if (fGetc(uart5) == 'G') {
                        TimeoutReset(tid);
                        x = ((signed char) fGetc(uart5)) * 0.25f/127.0f;
                        y = ((signed char) fGetc(uart5)) * 0.25f/127.0f;
                        w = ((signed char) fGetc(uart5)) * 0.25f/127.0f;
                        doMotorState(x,y,w);
                        SetPin(PIN_F2, true);
                }
        }
}
