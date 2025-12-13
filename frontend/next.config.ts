import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  allowedDevOrigins: ["http://58.225.113.125:3015"],
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
