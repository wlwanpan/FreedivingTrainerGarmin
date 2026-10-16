import Toybox.Lang;

const APP_UUID as String = "0328696e-cb77-51ad-9d18-afcb600b4221";
const WATCH_DETAIL as String = "garmin";
const SOURCE_WATCH as String = "watch";

const STORAGE_PENDING as String = "pendingSessionCompletions";
const STORAGE_LANGUAGE as String = "preferredLanguage";
const STORAGE_HAPTIC as String = "trainingHapticEnabled";
const STORAGE_SOUND as String = "trainingSoundEnabled";

const TYPE_NEXT_SESSION as String = "nextSession";
const TYPE_PHONE_TRAINING as String = "phoneTraining";
const TYPE_WATCH_TRAINING as String = "watchTraining";
const TYPE_HEART_RATE as String = "heartRate";
const TYPE_SESSION_COMPLETE as String = "sessionComplete";
const TYPE_ACK as String = "ack";

const PHASE_BREATHE as String = "Breathe";
const PHASE_HOLD as String = "Hold";
const PHASE_REST as String = "Rest";

const PAGE_PLAN as Number = 0;
const PAGE_CO2 as Number = 1;
const PAGE_O2 as Number = 2;

const DEFAULT_BREATHE_UP as Number = 60;
const DEFAULT_CO2_HOLD as Number = 90;
const DEFAULT_CO2_REST as Number = 120;
const DEFAULT_CO2_STEP as Number = 15;
const DEFAULT_CO2_ROUNDS as Number = 8;
const DEFAULT_O2_HOLD as Number = 60;
const DEFAULT_O2_STEP as Number = 15;
const DEFAULT_O2_REST as Number = 120;
const DEFAULT_O2_ROUNDS as Number = 8;

const MAX_ROUNDS as Number = 40;
const MAX_HR_SAMPLES as Number = 40;
const HR_MIN_GAP_SEC as Number = 10;
const TICK_MS as Number = 1000;
const TRAINING_PULSE_SEC as Number = 15;
const MAX_PENDING as Number = 5;

(:color)
const COLOR_BG as Number = 0x0D2B38;
(:color)
const COLOR_TEXT as Number = 0xF4F9F9;
(:color)
const COLOR_MUTED as Number = 0x52798A;
(:color)
const COLOR_HOLD as Number = 0x14B8A6;
(:color)
const COLOR_REST as Number = 0x06B6D4;
(:color)
const COLOR_BREATHE as Number = 0x0D9488;
(:color)
const COLOR_ALERT as Number = 0xF43F5E;
(:color)
const COLOR_PAUSED as Number = 0x94A3B8;

(:mono)
const COLOR_BG as Number = 0x000000;
(:mono)
const COLOR_TEXT as Number = 0xFFFFFF;
(:mono)
const COLOR_MUTED as Number = 0xFFFFFF;
(:mono)
const COLOR_HOLD as Number = 0xFFFFFF;
(:mono)
const COLOR_REST as Number = 0xFFFFFF;
(:mono)
const COLOR_BREATHE as Number = 0xFFFFFF;
(:mono)
const COLOR_ALERT as Number = 0xFFFFFF;
(:mono)
const COLOR_PAUSED as Number = 0xFFFFFF;
