"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function useScrollFocusCards(itemCount: number) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [focusedIndex, setFocusedIndex] = useState(0);

  const updateFocus = useCallback(() => {
    const container = scrollRef.current;
    if (!container || itemCount === 0) return;

    const containerRect = container.getBoundingClientRect();
    const centerX = containerRect.left + containerRect.width / 2;

    const children = Array.from(container.children) as HTMLElement[];
    let closest = 0;
    let minDist = Infinity;

    children.forEach((child, index) => {
      const rect = child.getBoundingClientRect();
      const childCenter = rect.left + rect.width / 2;
      const dist = Math.abs(childCenter - centerX);
      if (dist < minDist) {
        minDist = dist;
        closest = index;
      }
    });

    setFocusedIndex(closest);
  }, [itemCount]);

  useEffect(() => {
    const container = scrollRef.current;
    if (!container) return;

    updateFocus();
    container.addEventListener("scroll", updateFocus, { passive: true });
    window.addEventListener("resize", updateFocus);

    return () => {
      container.removeEventListener("scroll", updateFocus);
      window.removeEventListener("resize", updateFocus);
    };
  }, [updateFocus]);

  const cardClass = (index: number) =>
    index === focusedIndex
      ? "opacity-100 scale-100 border-primary/40 shadow-sm snap-center"
      : "opacity-40 blur-[0.5px] scale-95 snap-center";

  return { scrollRef, focusedIndex, cardClass };
}
