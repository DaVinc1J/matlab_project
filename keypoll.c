#include "mex.h"
#include <ApplicationServices/ApplicationServices.h>

typedef struct {
    CGKeyCode code;
    const char* name;
} KeyMap;

KeyMap keymap[] = {
    {0, "a"}, {1, "s"}, {2, "d"}, {3, "f"}, {4, "h"}, {5, "g"}, {6, "z"}, {7, "x"},
    {8, "c"}, {9, "v"}, {11, "b"}, {12, "q"}, {13, "w"}, {14, "e"}, {15, "r"},
    {16, "y"}, {17, "t"}, {31, "o"}, {32, "u"}, {34, "i"}, {35, "p"}, {37, "l"},
    {38, "j"}, {40, "k"}, {45, "n"}, {46, "m"},

    {18, "1"}, {19, "2"}, {20, "3"}, {21, "4"}, {23, "5"}, {22, "6"}, {26, "7"},
    {28, "8"}, {25, "9"}, {29, "0"},

    {27, "-"}, {24, "="}, {33, "["}, {30, "]"}, {42, "\\"},
    {41, ";"}, {39, "'"}, {43, ","}, {47, "."}, {44, "/"},

    {56, "shift_l"}, {60, "shift_r"},
    {59, "control_l"}, {62, "control_r"},
    {58, "alt_l"}, {61, "alt_r"},
    {55, "cmd_l"}, {54, "cmd_r"},

    {49, "space"}, {36, "return"}, {51, "delete"}, {48, "tab"}, {53, "escape"},
    {123, "left"}, {124, "right"}, {125, "down"}, {126, "up"}
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int n_keys = sizeof(keymap) / sizeof(KeyMap);
    const char **field_names = mxCalloc(n_keys, sizeof(char*));

    for (int i = 0; i < n_keys; i++) {
        field_names[i] = keymap[i].name;
    }

    plhs[0] = mxCreateStructMatrix(1, 1, n_keys, field_names);

    for (int i = 0; i < n_keys; i++) {
        bool is_down = CGEventSourceKeyState(kCGEventSourceStateHIDSystemState, keymap[i].code);
        mxArray *val = mxCreateLogicalScalar(is_down);
        mxSetField(plhs[0], 0, keymap[i].name, val);
    }

    mxFree((void*)field_names);
}
