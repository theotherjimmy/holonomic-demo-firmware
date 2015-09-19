#include <main.h>
#include <RASLib/inc/common.h>
#include <RASLib/inc/motor.h>
#include <RASLib/inc/gpio.h>
#include <RASLib/inc/time.h>

static int ledState = 0;

void ToggleLED (void) {
        SetPin(PIN_F1, ledState & 1);
        SetPin(PIN_F2, ledState & 2);
        SetPin(PIN_F3, ledState & 4);
        ++ledState;
}

struct outputVector {
        float x, y, w;
};

struct motorState {
        struct motorState * nextState;
        struct outputVector out;
};

static struct motorState states[3] = {
          { .nextState = &states[1]
            , .out = { .x = 0.0, .y = 0.2, .w = 0.0}}
        , { .nextState = &states[2]
            , .out = { .x = 0.2, .y = 0.0, .w = 0.0}}
        , { .nextState = &states[0]
            , .out = { .x = 0.0, .y = 0.0, .w = 0.2}}

};

static struct motorState *curState = &states[0];

static tMotor * motors[4];

void doMotorState (void) {
        struct outputVector out = curState->out;
        SetMotor(motors[0], - out.w - out.y + out.x);
        SetMotor(motors[1], - out.w - out.y - out.x);
        SetMotor(motors[2], - out.w + out.y + out.x);
        SetMotor(motors[3], - out.w + out.y - out.x);
        curState = curState->nextState;
}

int main (void) {
        int i = 0;
        int pid = 0;
        for (; i < 4; ++i) {
                motors[i] = InitializeServoMotor(i + PIN_D0, false);
        }
        pid = CallEvery(ToggleLED, 0, 0.25);
        doMotorState();
        Wait(2.0);
        doMotorState();
        Wait(2.0);
        doMotorState();
        Wait(2.0);
        CallStop(pid);
        for(i = 0; i < 4; ++i) SetMotor(motors[i], 0.0);
        ToggleLED();
        while (1)
                asm volatile ("nop");
}
