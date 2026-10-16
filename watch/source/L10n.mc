import Toybox.Lang;

var gLanguage as String = "en";

function setLanguage(value as String?) as Void {
    if (value == null) {
        return;
    }
    var code = value as String;
    if (code.equals("en") || code.equals("fr") || code.equals("es") || code.equals("ko") || code.equals("de")) {
        gLanguage = code;
    }
}

function tr(key as String) as String {
    if (gLanguage.equals("fr")) {
        return trFr(key);
    }
    if (gLanguage.equals("es")) {
        return trEs(key);
    }
    if (gLanguage.equals("de")) {
        return trDe(key);
    }
    if (gLanguage.equals("ko")) {
        return trKo(key);
    }
    return trEn(key);
}

function trPhase(title as String) as String {
    if (title.equals(PHASE_HOLD)) {
        return tr("holdPhase");
    }
    if (title.equals(PHASE_REST)) {
        return tr("restPhase");
    }
    if (title.equals(PHASE_BREATHE)) {
        return tr("breathePhase");
    }
    return title;
}

function holdDetail(tableType as String, time as String, count as Number) as String {
    var prefix = tableType.equals("o2") ? tr("holdsFrom") + " " + time : tr("hold") + " " + time;
    var rounds = count == 1 ? tr("round") : tr("rounds");
    return prefix + " · " + count.toString() + " " + rounds;
}

function roundOf(n as Number, total as Number) as String {
    return tr("round") + " " + n.toString() + " / " + total.toString();
}

function trEn(key as String) as String {
    if (key.equals("start")) { return "Start"; }
    if (key.equals("pause")) { return "Pause"; }
    if (key.equals("resume")) { return "Resume"; }
    if (key.equals("exit")) { return "Exit"; }
    if (key.equals("exitTitle")) { return "Exit training?"; }
    if (key.equals("okay")) { return "Okay"; }
    if (key.equals("saved")) { return "Saved"; }
    if (key.equals("paused")) { return "Paused"; }
    if (key.equals("waitingPhone")) { return "Waiting for iPhone"; }
    if (key.equals("sentToPhone")) { return "Sent to iPhone"; }
    if (key.equals("weekComplete")) { return "Week complete"; }
    if (key.equals("savedOnPhone")) { return "Saved on iPhone"; }
    if (key.equals("unlockLifetime")) { return "Unlock on iPhone"; }
    if (key.equals("choosePlan")) { return "Choose a plan on iPhone"; }
    if (key.equals("trainingOnPhone")) { return "Training on iPhone"; }
    if (key.equals("holdPhase")) { return "Hold"; }
    if (key.equals("restPhase")) { return "Rest"; }
    if (key.equals("breathePhase")) { return "Breathe"; }
    if (key.equals("breatheUp")) { return "Breathe-up"; }
    if (key.equals("hold")) { return "Hold"; }
    if (key.equals("holdsFrom")) { return "Holds from"; }
    if (key.equals("round")) { return "Round"; }
    if (key.equals("rounds")) { return "rounds"; }
    if (key.equals("plan")) { return "Plan"; }
    if (key.equals("co2")) { return "CO2"; }
    if (key.equals("o2")) { return "O2"; }
    if (key.equals("erased")) { return "iPhone data was erased."; }
    if (key.equals("planChanged")) { return "Plan changed on iPhone."; }
    if (key.equals("stayForeground")) { return "Keep this app open"; }
    if (key.equals("offline")) { return "Not connected"; }
    return key;
}

function trFr(key as String) as String {
    if (key.equals("start")) { return "Démarrer"; }
    if (key.equals("pause")) { return "Pause"; }
    if (key.equals("resume")) { return "Reprendre"; }
    if (key.equals("exit")) { return "Quitter"; }
    if (key.equals("exitTitle")) { return "Quitter ?"; }
    if (key.equals("okay")) { return "OK"; }
    if (key.equals("saved")) { return "Enregistré"; }
    if (key.equals("paused")) { return "En pause"; }
    if (key.equals("waitingPhone")) { return "En attente de l'iPhone"; }
    if (key.equals("sentToPhone")) { return "Envoyé à l'iPhone"; }
    if (key.equals("weekComplete")) { return "Semaine terminée"; }
    if (key.equals("savedOnPhone")) { return "Enregistré sur iPhone"; }
    if (key.equals("unlockLifetime")) { return "Débloquez sur iPhone"; }
    if (key.equals("choosePlan")) { return "Choisissez un plan sur iPhone"; }
    if (key.equals("trainingOnPhone")) { return "Entraînement sur iPhone"; }
    if (key.equals("holdPhase")) { return "Apnée"; }
    if (key.equals("restPhase")) { return "Repos"; }
    if (key.equals("breathePhase")) { return "Respiration"; }
    if (key.equals("breatheUp")) { return "Préparation"; }
    if (key.equals("hold")) { return "Apnée"; }
    if (key.equals("holdsFrom")) { return "Apnées à partir de"; }
    if (key.equals("round")) { return "Round"; }
    if (key.equals("rounds")) { return "rounds"; }
    if (key.equals("plan")) { return "Plan"; }
    if (key.equals("erased")) { return "Données iPhone effacées."; }
    if (key.equals("planChanged")) { return "Plan modifié sur iPhone."; }
    if (key.equals("stayForeground")) { return "Gardez l'app ouverte"; }
    if (key.equals("offline")) { return "Non connecté"; }
    return trEn(key);
}

function trEs(key as String) as String {
    if (key.equals("start")) { return "Empezar"; }
    if (key.equals("pause")) { return "Pausar"; }
    if (key.equals("resume")) { return "Reanudar"; }
    if (key.equals("exit")) { return "Salir"; }
    if (key.equals("exitTitle")) { return "¿Salir?"; }
    if (key.equals("okay")) { return "Vale"; }
    if (key.equals("saved")) { return "Guardado"; }
    if (key.equals("paused")) { return "Pausado"; }
    if (key.equals("waitingPhone")) { return "Esperando el iPhone"; }
    if (key.equals("sentToPhone")) { return "Enviado al iPhone"; }
    if (key.equals("weekComplete")) { return "Semana completa"; }
    if (key.equals("savedOnPhone")) { return "Guardado en iPhone"; }
    if (key.equals("unlockLifetime")) { return "Desbloquea en iPhone"; }
    if (key.equals("choosePlan")) { return "Elige un plan en iPhone"; }
    if (key.equals("trainingOnPhone")) { return "Entrenando en iPhone"; }
    if (key.equals("holdPhase")) { return "Apnea"; }
    if (key.equals("restPhase")) { return "Descanso"; }
    if (key.equals("breathePhase")) { return "Respiración"; }
    if (key.equals("breatheUp")) { return "Preparación"; }
    if (key.equals("hold")) { return "Apnea"; }
    if (key.equals("holdsFrom")) { return "Apneas desde"; }
    if (key.equals("round")) { return "Ronda"; }
    if (key.equals("rounds")) { return "rondas"; }
    if (key.equals("plan")) { return "Plan"; }
    if (key.equals("erased")) { return "Datos del iPhone borrados."; }
    if (key.equals("planChanged")) { return "El plan cambió en iPhone."; }
    if (key.equals("stayForeground")) { return "Mantén la app abierta"; }
    if (key.equals("offline")) { return "Sin conexión"; }
    return trEn(key);
}

function trDe(key as String) as String {
    if (key.equals("start")) { return "Start"; }
    if (key.equals("pause")) { return "Pause"; }
    if (key.equals("resume")) { return "Weiter"; }
    if (key.equals("exit")) { return "Beenden"; }
    if (key.equals("exitTitle")) { return "Beenden?"; }
    if (key.equals("okay")) { return "OK"; }
    if (key.equals("saved")) { return "Gespeichert"; }
    if (key.equals("paused")) { return "Pausiert"; }
    if (key.equals("waitingPhone")) { return "Warte auf iPhone"; }
    if (key.equals("sentToPhone")) { return "An iPhone gesendet"; }
    if (key.equals("weekComplete")) { return "Woche fertig"; }
    if (key.equals("savedOnPhone")) { return "Auf iPhone gespeichert"; }
    if (key.equals("unlockLifetime")) { return "Auf iPhone freischalten"; }
    if (key.equals("choosePlan")) { return "Plan auf iPhone wählen"; }
    if (key.equals("trainingOnPhone")) { return "Training auf iPhone"; }
    if (key.equals("holdPhase")) { return "Halt"; }
    if (key.equals("restPhase")) { return "Pause"; }
    if (key.equals("breathePhase")) { return "Atmen"; }
    if (key.equals("breatheUp")) { return "Einatmen"; }
    if (key.equals("hold")) { return "Halt"; }
    if (key.equals("holdsFrom")) { return "Halten ab"; }
    if (key.equals("round")) { return "Runde"; }
    if (key.equals("rounds")) { return "Runden"; }
    if (key.equals("plan")) { return "Plan"; }
    if (key.equals("erased")) { return "iPhone-Daten gelöscht."; }
    if (key.equals("planChanged")) { return "Plan auf iPhone geändert."; }
    if (key.equals("stayForeground")) { return "App geöffnet lassen"; }
    if (key.equals("offline")) { return "Nicht verbunden"; }
    return trEn(key);
}

function trKo(key as String) as String {
    if (key.equals("start")) { return "시작"; }
    if (key.equals("pause")) { return "일시정지"; }
    if (key.equals("resume")) { return "계속"; }
    if (key.equals("exit")) { return "종료"; }
    if (key.equals("exitTitle")) { return "종료할까요?"; }
    if (key.equals("okay")) { return "확인"; }
    if (key.equals("saved")) { return "저장됨"; }
    if (key.equals("paused")) { return "일시정지"; }
    if (key.equals("waitingPhone")) { return "iPhone 대기 중"; }
    if (key.equals("sentToPhone")) { return "iPhone으로 전송됨"; }
    if (key.equals("weekComplete")) { return "주 완료"; }
    if (key.equals("savedOnPhone")) { return "iPhone에 저장됨"; }
    if (key.equals("unlockLifetime")) { return "iPhone에서 잠금 해제"; }
    if (key.equals("choosePlan")) { return "iPhone에서 플랜 선택"; }
    if (key.equals("trainingOnPhone")) { return "iPhone에서 훈련 중"; }
    if (key.equals("holdPhase")) { return "숨참기"; }
    if (key.equals("restPhase")) { return "휴식"; }
    if (key.equals("breathePhase")) { return "호흡"; }
    if (key.equals("breatheUp")) { return "준비 호흡"; }
    if (key.equals("hold")) { return "숨참기"; }
    if (key.equals("holdsFrom")) { return "숨참기 시작"; }
    if (key.equals("round")) { return "라운드"; }
    if (key.equals("rounds")) { return "라운드"; }
    if (key.equals("plan")) { return "플랜"; }
    if (key.equals("erased")) { return "iPhone 데이터가 삭제되었습니다."; }
    if (key.equals("planChanged")) { return "iPhone에서 플랜이 변경되었습니다."; }
    if (key.equals("stayForeground")) { return "앱을 열어 두세요"; }
    if (key.equals("offline")) { return "연결 안 됨"; }
    return trEn(key);
}
