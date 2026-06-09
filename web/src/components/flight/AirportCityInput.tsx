"use client";

import {
  airportDisplayLabel,
  airportSubtitle,
  searchAirports,
  type AirportEntry,
} from "@/lib/airports";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useId, useRef, useState } from "react";

type Props = {
  label: string;
  value: string;
  onChange: (iata: string) => void;
  ariaLabel?: string;
};

export function AirportCityInput({
  label,
  value,
  onChange,
  ariaLabel,
}: Props) {
  const locale = useLocale();
  const t = useTranslations("home");
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [highlight, setHighlight] = useState(0);
  const [results, setResults] = useState<AirportEntry[]>([]);

  useEffect(() => {
    if (!open) return;
    setResults(searchAirports(query, locale));
    setHighlight(0);
  }, [query, open, locale]);

  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, []);

  function select(entry: AirportEntry) {
    onChange(entry.iata);
    setQuery("");
    setOpen(false);
  }

  function onKeyDown(e: React.KeyboardEvent) {
    if (!open && (e.key === "ArrowDown" || e.key === "Enter")) {
      setOpen(true);
      return;
    }
    if (!open) return;

    if (e.key === "ArrowDown") {
      e.preventDefault();
      setHighlight((h) => Math.min(h + 1, results.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setHighlight((h) => Math.max(h - 1, 0));
    } else if (e.key === "Enter" && results[highlight]) {
      e.preventDefault();
      select(results[highlight]);
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  }

  const iata = value.toUpperCase();
  const subtitle = airportSubtitle(iata, locale);

  return (
    <div
      ref={rootRef}
      className={`flight-field flight-airport-field relative border-b border-border-subtle lg:border-b-0 lg:border-e ${open ? "z-[300]" : ""}`}
    >
      <span className="flight-field-label">{label}</span>

      <div className="border-b border-border-subtle pb-2">
        <span className="flight-iata-display block" dir="ltr">
          {iata || "—"}
        </span>
      </div>

      <span className="flight-field-sub mt-1 block" dir="ltr">
        {subtitle}
      </span>

      <div className="relative mt-2">
        <input
          type="text"
          role="combobox"
          aria-expanded={open}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-label={ariaLabel ?? label}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={onKeyDown}
          placeholder={t("citySearchPlaceholder")}
          className="flight-city-search-input w-full"
          autoComplete="off"
        />

        {open && results.length > 0 && (
          <ul id={listId} role="listbox" className="airport-suggest-list">
            {results.map((entry, index) => (
              <li key={entry.iata} role="option" aria-selected={index === highlight}>
                <button
                  type="button"
                  className={`airport-suggest-item ${index === highlight ? "airport-suggest-item--active" : ""}`}
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => select(entry)}
                >
                  <span className="airport-suggest-iata" dir="ltr">
                    {entry.iata}
                  </span>
                  <span className="airport-suggest-city">
                    {airportDisplayLabel(entry, locale)}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
