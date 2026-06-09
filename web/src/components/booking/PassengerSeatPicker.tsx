"use client";

type Props = {
  passengerIndex: number;
  seats: string[];
  value: string;
  assignedElsewhere: Set<string>;
  onChange: (seat: string) => void;
  labels: {
    passengerSeat: string;
    chooseSeat: string;
  };
};

export function PassengerSeatPicker({
  passengerIndex,
  seats,
  value,
  assignedElsewhere,
  onChange,
  labels,
}: Props) {
  const options = seats.filter((seat) => seat === value || !assignedElsewhere.has(seat));

  return (
    <fieldset className="mt-4">
      <legend className="text-xs font-bold uppercase text-muted">{labels.passengerSeat}</legend>
      <div className="mt-2 flex flex-wrap gap-2">
        {options.map((seat) => (
          <label
            key={seat}
            className={`cursor-pointer rounded-lg border px-3 py-2 text-xs font-extrabold transition-colors ${
              value === seat
                ? "border-primary bg-primary text-primary-foreground"
                : "border-border-strong bg-surface text-foreground hover:border-primary"
            }`}
          >
            <input
              type="radio"
              name={`passenger-seat-${passengerIndex}`}
              value={seat}
              checked={value === seat}
              onChange={() => onChange(seat)}
              className="sr-only"
            />
            <span dir="ltr">{seat}</span>
          </label>
        ))}
        {options.length === 0 && (
          <span className="text-xs text-muted">{labels.chooseSeat}</span>
        )}
      </div>
    </fieldset>
  );
}
