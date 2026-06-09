"use client";

import {
  cabinForRow,
  cabinRowRanges,
  type SeatCabin,
} from "@/lib/seat-cabin";

const DEFAULT_COLUMNS = ["A", "B", "C", "D", "E", "F"];

const CABIN_STYLES: Record<
  SeatCabin,
  { idle: string; selected: string; legend: string }
> = {
  First: {
    idle: "border-amber-400/40 bg-amber-500/10 text-amber-100 hover:border-amber-400 hover:text-amber-300",
    selected: "border-amber-400 bg-amber-400 text-slate-900",
    legend: "border-amber-400/50 bg-amber-500/15",
  },
  Business: {
    idle: "border-sky-400/40 bg-sky-500/10 text-sky-100 hover:border-sky-400 hover:text-sky-300",
    selected: "border-sky-400 bg-sky-400 text-slate-900",
    legend: "border-sky-400/50 bg-sky-500/15",
  },
  Economy: {
    idle: "border-border-strong bg-surface text-foreground hover:border-primary hover:text-primary",
    selected: "border-primary bg-primary text-primary-foreground",
    legend: "border-border-strong bg-surface",
  },
};

type Labels = {
  seatTaken: string;
  seatAvailable: string;
  selectedSeat: string;
  selectedSeats?: string;
  pickSeatHint: string;
  selectSeatsCount?: string;
  cabinLegend: string;
  cabinSectionFirst: string;
  cabinSectionBusiness: string;
  cabinSectionEconomy: string;
};

type BaseProps = {
  rows: number;
  columns?: string[];
  availableSeats: string[];
  takenSeats: string[];
  labels: Labels;
};

type SingleProps = BaseProps & {
  mode?: "single";
  value: string;
  onChange: (seat: string) => void;
  maxSelections?: never;
};

type MultiProps = BaseProps & {
  mode: "multi";
  value: string[];
  maxSelections: number;
  onChange: (seats: string[]) => void;
};

type Props = SingleProps | MultiProps;

function seatLabel(row: number, col: string) {
  return `${row}${col}`;
}

function sectionLabel(cabin: SeatCabin, labels: Labels): string {
  if (cabin === "First") return labels.cabinSectionFirst;
  if (cabin === "Business") return labels.cabinSectionBusiness;
  return labels.cabinSectionEconomy;
}

function normalizeSelected(value: string | string[], mode: "single" | "multi"): string[] {
  if (mode === "multi") {
    return Array.isArray(value) ? value : value ? [value] : [];
  }
  const single = Array.isArray(value) ? (value[0] ?? "") : value;
  return single ? [single] : [];
}

export function SeatMap(props: Props) {
  const {
    rows,
    columns = DEFAULT_COLUMNS,
    availableSeats,
    takenSeats,
    labels,
  } = props;
  const mode = props.mode ?? "single";
  const selected = normalizeSelected(props.value, mode);
  const selectedSet = new Set(selected);
  const selectionLimit = props.mode === "multi" ? props.maxSelections : 1;

  function toggleSeat(seat: string) {
    if (mode === "single") {
      (props as SingleProps).onChange(seat);
      return;
    }
    const multi = props as MultiProps;
    const limit = multi.maxSelections;
    if (selectedSet.has(seat)) {
      multi.onChange(selected.filter((s) => s !== seat));
      return;
    }
    if (selected.length >= limit) return;
    multi.onChange([...selected, seat]);
  }

  const availableSet = new Set(availableSeats);
  const takenSet = new Set(takenSeats);
  const leftCols = columns.slice(0, 3);
  const rightCols = columns.slice(3, 6);
  const ranges = cabinRowRanges(rows);

  const rowsBySection = ranges.map((range) => ({
    ...range,
    label: sectionLabel(range.cabin, labels),
    rows: Array.from({ length: range.to - range.from + 1 }, (_, i) => range.from + i),
  }));

  const selectionLabel =
    mode === "multi" && labels.selectSeatsCount
      ? labels.selectSeatsCount
      : null;

  return (
    <div className="mt-4" dir="ltr">
      <p className="mb-3 text-xs text-muted">{labels.pickSeatHint}</p>
      {selectionLabel && (
        <p className="mb-3 text-xs font-semibold text-primary">{selectionLabel}</p>
      )}

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <span className="text-[10px] font-bold uppercase tracking-wide text-muted">
          {labels.cabinLegend}:
        </span>
        {(["First", "Business", "Economy"] as SeatCabin[]).map((cabin) => (
          <div key={cabin} className="flex items-center gap-1.5">
            <span
              className={`h-4 w-4 rounded border ${CABIN_STYLES[cabin].legend}`}
              aria-hidden
            />
            <span className="text-[10px] font-semibold text-muted">
              {sectionLabel(cabin, labels)}
            </span>
          </div>
        ))}
      </div>

      <div className="overflow-x-auto rounded-2xl border border-border-subtle bg-surface p-4">
        <div className="mb-3 flex justify-center">
          <div className="rounded-full border border-border-subtle px-6 py-1 text-[10px] font-bold uppercase tracking-widest text-muted">
            Front
          </div>
        </div>

        <div className="max-h-[420px] space-y-4 overflow-y-auto overflow-x-auto pr-1">
          {rowsBySection.map((section) => (
            <div key={section.cabin}>
              <div className="mb-2 flex items-center gap-2">
                <span
                  className={`h-2.5 w-2.5 rounded-full border ${CABIN_STYLES[section.cabin].legend}`}
                  aria-hidden
                />
                <p className="text-[10px] font-extrabold uppercase tracking-widest text-muted">
                  {section.label}
                </p>
                <div className="h-px flex-1 bg-foreground/10" />
              </div>

              <div className="space-y-1.5">
                {section.rows.map((row) => (
                  <div key={row} className="flex items-center justify-center gap-2">
                    <span className="w-6 text-center text-[10px] font-bold text-muted">
                      {row}
                    </span>
                    <div className="flex gap-1">
                      {leftCols.map((col) => {
                        const seat = seatLabel(row, col);
                        return (
                          <SeatButton
                            key={seat}
                            seat={seat}
                            cabin={cabinForRow(row, rows)}
                            isTaken={takenSet.has(seat)}
                            isAvailable={availableSet.has(seat)}
                            isSelected={selectedSet.has(seat)}
                            selectionFull={
                              mode === "multi" &&
                              !selectedSet.has(seat) &&
                              selected.length >= selectionLimit
                            }
                            onToggle={() => toggleSeat(seat)}
                            labels={labels}
                          />
                        );
                      })}
                    </div>
                    <div className="mx-1 w-4" aria-hidden />
                    <div className="flex gap-1">
                      {rightCols.map((col) => {
                        const seat = seatLabel(row, col);
                        return (
                          <SeatButton
                            key={seat}
                            seat={seat}
                            cabin={cabinForRow(row, rows)}
                            isTaken={takenSet.has(seat)}
                            isAvailable={availableSet.has(seat)}
                            isSelected={selectedSet.has(seat)}
                            selectionFull={
                              mode === "multi" &&
                              !selectedSet.has(seat) &&
                              selected.length >= selectionLimit
                            }
                            onToggle={() => toggleSeat(seat)}
                            labels={labels}
                          />
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {selected.length > 0 && (
        <p className="mt-4 text-sm font-bold text-primary">
          {mode === "multi" && labels.selectedSeats
            ? labels.selectedSeats
            : labels.selectedSeat}
          :{" "}
          <span dir="ltr">{selected.join(", ")}</span>
        </p>
      )}
    </div>
  );
}

function SeatButton({
  seat,
  cabin,
  isTaken,
  isAvailable,
  isSelected,
  selectionFull,
  onToggle,
  labels,
}: {
  seat: string;
  cabin: SeatCabin;
  isTaken: boolean;
  isAvailable: boolean;
  isSelected: boolean;
  selectionFull: boolean;
  onToggle: () => void;
  labels: Labels;
}) {
  const disabled = isTaken || !isAvailable || (selectionFull && !isSelected);

  let className =
    "flex h-8 w-8 items-center justify-center rounded-md border text-[10px] font-extrabold transition-colors ";

  if (isTaken) {
    className += "cursor-not-allowed border-border-subtle bg-foreground/5 text-muted line-through";
  } else if (isSelected) {
    className += CABIN_STYLES[cabin].selected;
  } else if (disabled) {
    className += "cursor-not-allowed border-border-subtle bg-foreground/5 text-muted opacity-50";
  } else {
    className += CABIN_STYLES[cabin].idle;
  }

  return (
    <button
      type="button"
      disabled={disabled}
      aria-label={`${seat} ${isTaken ? labels.seatTaken : labels.seatAvailable}`}
      aria-pressed={isSelected}
      className={className}
      onClick={onToggle}
    >
      {seat.slice(-1)}
    </button>
  );
}
