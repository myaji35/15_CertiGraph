import Link from "next/link";
import { auth } from "@clerk/nextjs/server";
import { LandingPageClient } from "@/components/landing/LandingPageClient";

export default async function Home() {
  const { userId } = await auth();

  return <LandingPageClient isLoggedIn={!!userId} />;
}
