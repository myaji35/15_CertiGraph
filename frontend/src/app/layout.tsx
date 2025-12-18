import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { koKR } from "@clerk/localizations";
import "./globals.css";

export const metadata: Metadata = {
  title: "ExamsGraph - AI 자격증 마스터",
  description: "사회복지사 1급 시험 대비를 위한 AI 기반 학습 플랫폼. PDF 문제집을 업로드하면 지능형 분석과 맞춤 학습을 제공합니다.",
  keywords: "사회복지사, 1급 시험, AI 학습, 시험 대비, 문제 은행",
  openGraph: {
    title: "ExamsGraph - AI 자격증 마스터",
    description: "사회복지사 1급 시험 대비 AI 학습 플랫폼",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider localization={koKR}>
      <html lang="ko">
        <body className="antialiased">
          {children}
        </body>
      </html>
    </ClerkProvider>
  );
}
