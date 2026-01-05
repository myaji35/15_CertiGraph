"use client";

import { MantineProvider, ColorSchemeScript } from "@mantine/core";
import { Notifications } from "@mantine/notifications";
import { theme } from "@/lib/theme";

export function Providers({ children }: { children: React.ReactNode }) {
    return (
        <MantineProvider theme={theme} defaultColorScheme="auto">
            <Notifications position="top-right" zIndex={2077} />
            {children}
        </MantineProvider>
    );
}

export { ColorSchemeScript };
