"use client";

import { createTheme, MantineColorsTuple } from "@mantine/core";

// ExamsGraph 브랜드 컬러
const brandBlue: MantineColorsTuple = [
    "#e6f2ff",
    "#cce0ff",
    "#99c2ff",
    "#66a3ff",
    "#3385ff",
    "#0066ff",
    "#0052cc",
    "#003d99",
    "#002966",
    "#001433",
];

const brandIndigo: MantineColorsTuple = [
    "#eef2ff",
    "#e0e7ff",
    "#c7d2fe",
    "#a5b4fc",
    "#818cf8",
    "#6366f1",
    "#4f46e5",
    "#4338ca",
    "#3730a3",
    "#312e81",
];

export const theme = createTheme({
    /** 기본 컬러 스킴 */
    primaryColor: "brandBlue",

    /** 커스텀 컬러 추가 */
    colors: {
        brandBlue,
        brandIndigo,
    },

    /** 폰트 패밀리 */
    fontFamily: 'var(--font-geist-sans), -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    fontFamilyMonospace: 'var(--font-geist-mono), Monaco, Courier, monospace',
    headings: {
        fontFamily: 'var(--font-geist-sans), -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        fontWeight: "700",
        sizes: {
            h1: { fontSize: "2.125rem", lineHeight: "2.5rem" },
            h2: { fontSize: "1.625rem", lineHeight: "2rem" },
            h3: { fontSize: "1.375rem", lineHeight: "1.75rem" },
            h4: { fontSize: "1.125rem", lineHeight: "1.5rem" },
        },
    },

    /** 둥근 모서리 */
    radius: {
        xs: "0.25rem",
        sm: "0.375rem",
        md: "0.5rem",
        lg: "0.625rem",
        xl: "0.75rem",
    },

    /** 기본 반지름 */
    defaultRadius: "md",

    /** 그림자 */
    shadows: {
        xs: "0 1px 2px 0 rgb(0 0 0 / 0.05)",
        sm: "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
        md: "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
        lg: "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
        xl: "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)",
    },

    /** 컴포넌트 기본값 */
    components: {
        Button: {
            defaultProps: {
                radius: "md",
            },
        },
        Card: {
            defaultProps: {
                radius: "lg",
                shadow: "sm",
                padding: "lg",
                withBorder: true,
            },
        },
        Paper: {
            defaultProps: {
                radius: "md",
                shadow: "sm",
                p: "md",
            },
        },
        Input: {
            defaultProps: {
                radius: "md",
            },
        },
        TextInput: {
            defaultProps: {
                radius: "md",
            },
        },
        Modal: {
            defaultProps: {
                radius: "lg",
                centered: true,
            },
        },
    },

    /** 기타 설정 */
    focusRing: "auto",
    cursorType: "pointer",
});
