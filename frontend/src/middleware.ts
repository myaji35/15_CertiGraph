import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Public routes that don't require authentication
const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/login(.*)',
  '/signup(.*)',
  '/pricing',
  '/api/webhook(.*)',
  '/api/health',
]);

// Protected routes that require authentication
const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/study-sets(.*)',
  '/certifications(.*)',
  '/knowledge-graph(.*)',
  '/test(.*)',
  '/admin(.*)',
  '/checkout(.*)',
  '/payment(.*)',
]);

export default clerkMiddleware(async (auth, req) => {
  const { userId } = await auth();

  // Allow public routes
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // Redirect to sign-in if accessing protected route without authentication
  if (isProtectedRoute(req) && !userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  // Admin routes require special permission (you can add role checking here)
  if (req.nextUrl.pathname.startsWith('/admin')) {
    // For now, we'll allow all authenticated users to admin
    // In production, you'd check for admin role
    if (!userId) {
      return NextResponse.redirect(new URL('/sign-in', req.url));
    }
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    // Skip Next.js internals and all static files, unless found in search params
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};