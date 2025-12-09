import NotionLayout from '@/components/layout/NotionLayout';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <NotionLayout>
      {children}
    </NotionLayout>
  );
}
