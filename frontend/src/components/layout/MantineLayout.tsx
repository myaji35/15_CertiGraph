"use client";

import React, { useState } from "react";
import {
    AppShell,
    Burger,
    Group,
    NavLink,
    ScrollArea,
    Text,
    UnstyledButton,
    useMantineColorScheme,
    ActionIcon,
    Avatar,
    Menu,
    Divider,
    Stack,
    Badge,
} from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import {
    IconHome,
    IconBook,
    IconBrain,
    IconChartBar,
    IconGraph,
    IconTarget,
    IconAward,
    IconCalendar,
    IconSettings,
    IconLogout,
    IconUser,
    IconMoon,
    IconSun,
    IconChevronRight,
} from "@tabler/icons-react";
import { usePathname, useRouter } from "next/navigation";
import { useUser, useClerk } from "@clerk/nextjs";
import Link from "next/link";

interface NavItem {
    label: string;
    icon: React.ElementType;
    path: string;
    badge?: string;
    children?: NavItem[];
}

const navigationItems: NavItem[] = [
    {
        label: "대시보드",
        icon: IconHome,
        path: "/dashboard",
    },
    {
        label: "학습 세트",
        icon: IconBook,
        path: "/dashboard/study",
    },
    {
        label: "시험",
        icon: IconBrain,
        path: "/dashboard/test",
    },
    {
        label: "분석",
        icon: IconChartBar,
        path: "/dashboard/analysis",
    },
    {
        label: "취약점",
        icon: IconTarget,
        path: "/dashboard/weak-points",
    },
    {
        label: "지식 그래프",
        icon: IconGraph,
        path: "/dashboard/knowledge-graph",
    },
    {
        label: "성취도",
        icon: IconAward,
        path: "/dashboard/achievements",
    },
    {
        label: "진도",
        icon: IconCalendar,
        path: "/dashboard/progress",
    },
];

export default function MantineLayout({ children }: { children: React.ReactNode }) {
    const [opened, { toggle, close }] = useDisclosure();
    const pathname = usePathname();
    const router = useRouter();
    const { user } = useUser();
    const { signOut } = useClerk();
    const { colorScheme, toggleColorScheme } = useMantineColorScheme();

    const isActive = (path: string) => {
        if (path === "/dashboard") {
            return pathname === path;
        }
        return pathname?.startsWith(path);
    };

    const handleSignOut = async () => {
        await signOut();
        router.push("/");
    };

    return (
        <AppShell
            header={{ height: 60 }}
            navbar={{
                width: 280,
                breakpoint: "sm",
                collapsed: { mobile: !opened },
            }}
            padding="md"
        >
            {/* Header */}
            <AppShell.Header>
                <Group h="100%" px="md" justify="space-between">
                    <Group>
                        <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />
                        <Link href="/dashboard" style={{ textDecoration: "none", color: "inherit" }}>
                            <Group gap="xs">
                                <IconBrain size={28} stroke={2} />
                                <Text size="xl" fw={700} style={{ letterSpacing: "-0.5px" }}>
                                    ExamsGraph
                                </Text>
                            </Group>
                        </Link>
                    </Group>

                    <Group>
                        {/* 다크 모드 토글 */}
                        <ActionIcon
                            variant="subtle"
                            size="lg"
                            onClick={() => toggleColorScheme()}
                            aria-label="Toggle color scheme"
                        >
                            {colorScheme === "dark" ? <IconSun size={20} /> : <IconMoon size={20} />}
                        </ActionIcon>

                        {/* 사용자 메뉴 */}
                        <Menu shadow="md" width={200}>
                            <Menu.Target>
                                <UnstyledButton>
                                    <Avatar
                                        src={user?.imageUrl}
                                        alt={user?.fullName || user?.username || "User"}
                                        radius="xl"
                                        size="md"
                                    />
                                </UnstyledButton>
                            </Menu.Target>

                            <Menu.Dropdown>
                                <Menu.Label>
                                    <Text size="sm" fw={500} truncate>
                                        {user?.fullName || user?.username || user?.emailAddresses[0]?.emailAddress}
                                    </Text>
                                </Menu.Label>
                                <Menu.Divider />

                                <Menu.Item
                                    leftSection={<IconUser size={16} />}
                                    onClick={() => router.push("/settings")}
                                >
                                    내 정보
                                </Menu.Item>
                                <Menu.Item
                                    leftSection={<IconSettings size={16} />}
                                    onClick={() => router.push("/settings")}
                                >
                                    설정
                                </Menu.Item>

                                <Menu.Divider />

                                <Menu.Item
                                    color="red"
                                    leftSection={<IconLogout size={16} />}
                                    onClick={handleSignOut}
                                >
                                    로그아웃
                                </Menu.Item>
                            </Menu.Dropdown>
                        </Menu>
                    </Group>
                </Group>
            </AppShell.Header>

            {/* Navbar */}
            <AppShell.Navbar p="md">
                <AppShell.Section grow component={ScrollArea}>
                    <Stack gap="xs">
                        {navigationItems.map((item) => {
                            const Icon = item.icon;
                            const active = isActive(item.path);

                            return (
                                <NavLink
                                    key={item.path}
                                    component={Link}
                                    href={item.path}
                                    label={item.label}
                                    leftSection={<Icon size={20} stroke={1.5} />}
                                    rightSection={
                                        item.badge ? (
                                            <Badge size="xs" color="red" circle>
                                                {item.badge}
                                            </Badge>
                                        ) : item.children ? (
                                            <IconChevronRight size={14} stroke={1.5} />
                                        ) : null
                                    }
                                    active={active}
                                    onClick={close}
                                    styles={{
                                        root: {
                                            borderRadius: "var(--mantine-radius-md)",
                                            fontWeight: active ? 600 : 500,
                                        },
                                    }}
                                />
                            );
                        })}
                    </Stack>
                </AppShell.Section>

                <AppShell.Section>
                    <Divider mb="md" />
                    <Text size="xs" c="dimmed" ta="center">
                        © 2025 ExamsGraph
                    </Text>
                </AppShell.Section>
            </AppShell.Navbar>

            {/* Main Content */}
            <AppShell.Main>{children}</AppShell.Main>
        </AppShell>
    );
}
