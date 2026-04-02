import { useState, useCallback, useRef } from "react";

export type LogEntry = {
  id: number;
  timestamp: Date;
  message: string;
  type: "info" | "success" | "error" | "spotlight";
}

let nextId = 0;

export function useActivityLog(maxEntries = 50) {
  const [entries, setEntries] = useState<LogEntry[]>([]);

  const log = useCallback(
    (message: string, type: LogEntry["type"] = "info") => {
      setEntries((prev) => {
        const entry: LogEntry = {
          id: nextId++,
          timestamp: new Date(),
          message,
          type,
        };
        const next = [...prev, entry];
        if (next.length > maxEntries) next.shift();
        return next;
      });
    },
    [maxEntries]
  );

  const clear = useCallback(() => setEntries([]), []);

  return { entries, log, clear };
}
