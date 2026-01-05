import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Shield, Home, Book, Users, Settings, LogOut, FileText, Award } from "lucide-react";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { userId } = await auth();

  if (!userId) {
    redirect("/sign-in");
  }

  // TODO: 추후 관리자 권한 체크 추가
  // const isAdmin = await checkAdminRole(userId);
  // if (!isAdmin) {
  //   redirect("/dashboard");
  // }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Admin Sidebar */}
      <div className="w-64 bg-white shadow-md">
        <div className="p-4 border-b">
          <div className="flex items-center gap-2">
            <Shield className="w-6 h-6 text-blue-600" />
            <h1 className="text-xl font-bold text-gray-900">관리자 패널</h1>
          </div>
        </div>

        <nav className="p-4">
          <ul className="space-y-2">
            <li>
              <Link
                href="/admin"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <Home className="w-5 h-5" />
                대시보드
              </Link>
            </li>
            <li>
              <Link
                href="/admin/content"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <Book className="w-5 h-5" />
                공식 콘텐츠 관리
              </Link>
            </li>
            <li>
              <Link
                href="/admin/users"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <Users className="w-5 h-5" />
                사용자 관리
              </Link>
            </li>
            <li>
              <Link
                href="/admin/certifications"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <Award className="w-5 h-5" />
                자격증 관리
              </Link>
            </li>
            <li>
              <Link
                href="/admin/statistics"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <FileText className="w-5 h-5" />
                통계 및 분석
              </Link>
            </li>
            <li>
              <Link
                href="/admin/settings"
                className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
              >
                <Settings className="w-5 h-5" />
                설정
              </Link>
            </li>
          </ul>
        </nav>

        <div className="absolute bottom-0 w-64 p-4 border-t">
          <Link
            href="/dashboard"
            className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-700 hover:text-gray-900"
          >
            <LogOut className="w-5 h-5" />
            사용자 모드로 전환
          </Link>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <div className="bg-white shadow-sm border-b">
          <div className="px-6 py-4">
            <div className="flex items-center justify-between">
              <h2 className="text-2xl font-semibold text-gray-900">ExamsGraph 관리자</h2>
              <div className="flex items-center gap-4">
                <span className="text-sm text-gray-500">관리자 모드</span>
                <Link
                  href="/"
                  className="text-sm text-blue-600 hover:text-blue-700"
                >
                  공개 사이트 보기
                </Link>
              </div>
            </div>
          </div>
        </div>
        <div className="p-6">
          {children}
        </div>
      </div>
    </div>
  );
}