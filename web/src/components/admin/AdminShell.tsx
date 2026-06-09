"use client";

import type { ReactNode } from "react";
import { useState } from "react";
import { AdminSidebar } from "./AdminSidebar";
import { AdminTopBar } from "./AdminTopBar";
import type { AdminShellProfile } from "./admin-shell-types";

type Props = {
  profile: AdminShellProfile;
  children: ReactNode;
};

/** Collapsed rail (icons) vs expanded (labels). */
export function AdminShell({ profile, children }: Props) {
  const [sidebarExpanded, setSidebarExpanded] = useState(false);

  const mainPadding = sidebarExpanded ? "pr-64" : "pr-16";

  return (
    <div className="admin-shell h-dvh overflow-hidden bg-background">
      <AdminSidebar
        profile={profile}
        expanded={sidebarExpanded}
        onToggle={() => setSidebarExpanded((v) => !v)}
      />
      <div
        className={`flex h-dvh min-w-0 flex-col transition-[padding] duration-300 ease-in-out ${mainPadding}`}
      >
        <AdminTopBar
          profile={profile}
          sidebarExpanded={sidebarExpanded}
          onSidebarToggle={() => setSidebarExpanded((v) => !v)}
        />
        <main className="min-h-0 min-w-0 flex-1 overflow-y-auto overflow-x-hidden p-4 sm:p-6 lg:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
