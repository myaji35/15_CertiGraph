import { SignUp } from "@clerk/nextjs";
import Link from "next/link";

export default function SignUpPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="mb-8 text-center">
        <Link href="/" className="text-2xl font-bold text-indigo-600">
          ExamsGraph
        </Link>
        <p className="mt-2 text-gray-600">AI 자격증 마스터</p>
      </div>
      <SignUp
        appearance={{
          elements: {
            rootBox: "mx-auto",
            card: "shadow-xl",
            headerTitle: "text-xl font-bold",
            headerSubtitle: "text-gray-500",
            socialButtonsBlockButton: "border border-gray-300 hover:bg-gray-50",
            formButtonPrimary: "bg-indigo-600 hover:bg-indigo-700",
            footerActionLink: "text-indigo-600 hover:text-indigo-700",
          },
        }}
        fallbackRedirectUrl="/dashboard"
        signInUrl="/sign-in"
      />
      <p className="mt-6 text-sm text-gray-500">
        이미 계정이 있으신가요?{" "}
        <Link href="/sign-in" className="text-indigo-600 hover:text-indigo-700 font-medium">
          로그인
        </Link>
      </p>
    </div>
  );
}
