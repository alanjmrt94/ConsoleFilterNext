package com.alanjmrt94.consolefilternext;

public class LogMessage {
    private final String timestamp;
    private final String thread;
    private final String level;
    private final String source;
    private final String message;

    public LogMessage(String timestamp, String thread, String level, String source, String message) {
        this.timestamp = timestamp;
        this.thread = thread;
        this.level = level;
        this.source = source;
        this.message = message;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public String getThread() {
        return thread;
    }

    public String getLevel() {
        return level;
    }

    public String getSource() {
        return source;
    }

    public String getMessage() {
        return message;
    }

    public String getFullMessage() {
        return String.format("[%s] [%s/%s] [%s]: %s", 
            timestamp, thread, level, source, message);
    }

    public boolean hasStackTraceHint() {
        return StackTraceDetector.looksLikeStackTrace(message);
    }
}