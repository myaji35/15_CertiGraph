"use client";

import { useState, useEffect, use } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import {
    Stack,
    Title,
    Text,
    Card,
    Group,
    Button,
    Badge,
    RingProgress,
    Center,
    Paper,
    SimpleGrid,
    Progress,
    Divider,
    ThemeIcon,
    Alert,
    Loader,
    Accordion,
    Radio,
} from "@mantine/core";
import {
    IconTrophy,
    IconTarget,
    IconClock,
    IconCheck,
    IconX,
    IconChartPie,
    IconBook,
    IconAlertCircle,
    IconChevronRight,
} from "@tabler/icons-react";
import Link from "next/link";

interface QuestionResult {
    question_id: string;
    question_text: string;
    options: string[];
    user_answer: number | null;
    correct_answer: number;
    is_correct: boolean;
    explanation?: string;
    passage?: string;
}

interface TestResult {
    session_id: string;
    study_set_id: string;
    study_set_name: string;
    score: number;
    total_questions: number;
    percentage: number;
    correct_count: number;
    wrong_count: number;
    unanswered_count: number;
    completed_at: string;
    time_taken_minutes?: number;
    questions: QuestionResult[];
}

export default function TestResultPage({ params }: { params: Promise<{ sessionId: string }> }) {
    const resolvedParams = use(params);
    const router = useRouter();
    const { getToken } = useAuth();
    const [result, setResult] = useState<TestResult | null>(null);
    const [loading, setLoading] = useState(true);
    const [showReview, setShowReview] = useState(false);

    useEffect(() => {
        fetchResult();
    }, []);

    const fetchResult = async () => {
        try {
            const token = await getToken();
            if (!token) return;

            const response = await fetch(
                `${process.env.NEXT_PUBLIC_API_URL}/tests/${resolvedParams.sessionId}/result`,
                {
                    headers: { Authorization: `Bearer ${token}` },
                }
            );

            if (!response.ok) {
                throw new Error("결과를 불러올 수 없습니다");
            }

            const data = await response.json();
            setResult(data.data);
        } catch (error: any) {
            console.error("Failed to fetch result:", error);
        } finally {
            setLoading(false);
        }
    };

    const [retestLoading, setRetestLoading] = useState(false);

    const handleRetest = async () => {
        if (!result) return;
        setRetestLoading(true);
        try {
            const token = await getToken();
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/tests/start`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    study_set_id: result.study_set_id,
                    mode: "wrong_only",
                    shuffle_options: true,
                }),
            });

            if (!response.ok) {
                throw new Error("시험을 시작할 수 없습니다.");
            }

            const data = await response.json();
            router.push(`/dashboard/test/${data.data.session_id}`);
        } catch (error) {
            console.error("Failed to start retest:", error);
            alert("시험 시작 중 오류가 발생했습니다.");
            setRetestLoading(false);
        }
    };

    if (loading || !result) {
        return (
            <Center h={400}>
                <Loader size="lg" />
            </Center>
        );
    }

    const isPassing = result.percentage >= 60;
    const wrongQuestions = result.questions.filter((q) => !q.is_correct);

    return (
        <Stack gap="xl" maw={1000} mx="auto">
            {/* Header */}
            <div>
                <Title order={1} mb="xs">
                    시험 결과 🎯
                </Title>
                <Text c="dimmed">{result.study_set_name}</Text>
            </div>

            {/* Score Card */}
            <Card shadow="md" padding="xl" radius="lg">
                <Group justify="space-between" align="flex-start">
                    <Stack gap="md" flex={1}>
                        <Badge
                            size="lg"
                            variant="light"
                            color={isPassing ? "green" : "red"}
                            leftSection={isPassing ? <IconCheck size={14} /> : <IconX size={14} />}
                        >
                            {isPassing ? "합격권" : "재도전 필요"}
                        </Badge>

                        <div>
                            <Text size="sm" c="dimmed" mb="xs">
                                획득 점수
                            </Text>
                            <Group align="baseline" gap="xs">
                                <Text size="3rem" fw={700} c={isPassing ? "green" : "red"}>
                                    {result.percentage}
                                </Text>
                                <Text size="xl" c="dimmed">
                                    점
                                </Text>
                            </Group>
                        </div>

                        <Group>
                            <div>
                                <Text size="xs" c="dimmed">
                                    정답
                                </Text>
                                <Text size="lg" fw={600} c="green">
                                    {result.correct_count}개
                                </Text>
                            </div>
                            <Divider orientation="vertical" />
                            <div>
                                <Text size="xs" c="dimmed">
                                    오답
                                </Text>
                                <Text size="lg" fw={600} c="red">
                                    {result.wrong_count}개
                                </Text>
                            </div>
                            <Divider orientation="vertical" />
                            <div>
                                <Text size="xs" c="dimmed">
                                    미답
                                </Text>
                                <Text size="lg" fw={600} c="gray">
                                    {result.unanswered_count}개
                                </Text>
                            </div>
                        </Group>

                        {result.time_taken_minutes && (
                            <Group gap="xs">
                                <IconClock size={16} />
                                <Text size="sm" c="dimmed">
                                    소요 시간: {result.time_taken_minutes}분
                                </Text>
                            </Group>
                        )}
                    </Stack>

                    {/* Ring Progress */}
                    <RingProgress
                        size={200}
                        thickness={20}
                        sections={[
                            { value: (result.correct_count / result.total_questions) * 100, color: "green" },
                            { value: (result.wrong_count / result.total_questions) * 100, color: "red" },
                            { value: (result.unanswered_count / result.total_questions) * 100, color: "gray" },
                        ]}
                        label={
                            <Center>
                                <ThemeIcon size="xl" radius="xl" color={isPassing ? "green" : "red"} variant="light">
                                    {isPassing ? <IconTrophy size={32} /> : <IconTarget size={32} />}
                                </ThemeIcon>
                            </Center>
                        }
                    />
                </Group>
            </Card>

            {/* Statistics */}
            <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="lg">
                <Paper p="lg" radius="md" withBorder>
                    <Group>
                        <ThemeIcon size="xl" radius="md" variant="light" color="green">
                            <IconCheck size={24} />
                        </ThemeIcon>
                        <div>
                            <Text size="xs" c="dimmed">
                                정답률
                            </Text>
                            <Text size="xl" fw={700}>
                                {result.percentage}%
                            </Text>
                        </div>
                    </Group>
                    <Progress
                        value={result.percentage}
                        size="sm"
                        mt="md"
                        color={isPassing ? "green" : "red"}
                    />
                </Paper>

                <Paper p="lg" radius="md" withBorder>
                    <Group>
                        <ThemeIcon size="xl" radius="md" variant="light" color="blue">
                            <IconChartPie size={24} />
                        </ThemeIcon>
                        <div>
                            <Text size="xs" c="dimmed">
                                총 문제 수
                            </Text>
                            <Text size="xl" fw={700}>
                                {result.total_questions}개
                            </Text>
                        </div>
                    </Group>
                </Paper>

                <Paper p="lg" radius="md" withBorder>
                    <Group>
                        <ThemeIcon size="xl" radius="md" variant="light" color="orange">
                            <IconTarget size={24} />
                        </ThemeIcon>
                        <div>
                            <Text size="xs" c="dimmed">
                                오답 수
                            </Text>
                            <Text size="xl" fw={700} c="red">
                                {result.wrong_count}개
                            </Text>
                        </div>
                    </Group>
                </Paper>
            </SimpleGrid>

            {/* Wrong Answers Alert */}
            {result.wrong_count > 0 && (
                <Alert icon={<IconAlertCircle size={16} />} color="orange" variant="light">
                    <Stack gap="xs">
                        <Text size="sm" fw={500}>
                            틀린 문제가 {result.wrong_count}개 있습니다
                        </Text>
                        <Text size="sm">
                            오답 노트를 통해 틀린 문제를 복습하고 실력을 향상시키세요!
                        </Text>
                    </Stack>
                </Alert>
            )}

            {/* Actions */}
            <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="lg">
                <Button
                    variant="light"
                    size="lg"
                    leftSection={<IconBook size={20} />}
                    onClick={() => setShowReview(true)}
                >
                    전체 문제 복습
                </Button>

                <Button
                    variant="light"
                    color="orange"
                    size="lg"
                    leftSection={<IconBook size={20} />}
                    component={Link}
                    href={`/dashboard/test/review/${resolvedParams.sessionId}`}
                    disabled={result.wrong_count === 0}
                >
                    오답노트 생성
                </Button>

                <Button
                    variant="light"
                    color="red"
                    size="lg"
                    leftSection={<IconX size={20} />}
                    onClick={handleRetest}
                    loading={retestLoading}
                    disabled={result.wrong_count === 0}
                >
                    오답만 복습
                </Button>

                <Button
                    variant="light"
                    color="green"
                    size="lg"
                    leftSection={<IconChevronRight size={20} />}
                    component={Link}
                    href="/dashboard/test"
                >
                    다시 시험보기
                </Button>
            </SimpleGrid>

            {/* Question Review (if toggled) */}
            {showReview && (
                <Card shadow="sm" padding="lg" radius="md">
                    <Group justify="space-between" mb="md">
                        <Text size="lg" fw={600}>
                            전체 문제 복습
                        </Text>
                        <Button variant="subtle" size="sm" onClick={() => setShowReview(false)}>
                            닫기
                        </Button>
                    </Group>

                    <Accordion variant="separated">
                        {result.questions.map((question, index) => (
                            <Accordion.Item key={question.question_id} value={question.question_id}>
                                <Accordion.Control
                                    icon={
                                        <ThemeIcon
                                            color={question.is_correct ? "green" : "red"}
                                            variant="light"
                                            size="sm"
                                        >
                                            {question.is_correct ? <IconCheck size={14} /> : <IconX size={14} />}
                                        </ThemeIcon>
                                    }
                                >
                                    <Text size="sm" fw={500}>
                                        Q{index + 1}. {question.question_text}
                                    </Text>
                                </Accordion.Control>
                                <Accordion.Panel>
                                    <Stack gap="md">
                                        {question.passage && (
                                            <Paper p="md" radius="md" bg="gray.0">
                                                <Text size="xs" fw={500} c="dimmed" mb="xs">
                                                    📄 지문
                                                </Text>
                                                <Text size="sm">{question.passage}</Text>
                                            </Paper>
                                        )}

                                        <Radio.Group value={question.correct_answer.toString()}>
                                            <Stack gap="xs">
                                                {question.options.map((option, optIndex) => {
                                                    const isUserAnswer = question.user_answer === optIndex;
                                                    const isCorrect = question.correct_answer === optIndex;

                                                    return (
                                                        <Radio
                                                            key={optIndex}
                                                            value={optIndex.toString()}
                                                            label={option}
                                                            disabled
                                                            styles={{
                                                                root: {
                                                                    padding: "0.75rem",
                                                                    borderRadius: "var(--mantine-radius-md)",
                                                                    border: "1px solid",
                                                                    borderColor: isCorrect
                                                                        ? "var(--mantine-color-green-6)"
                                                                        : isUserAnswer
                                                                            ? "var(--mantine-color-red-6)"
                                                                            : "var(--mantine-color-gray-3)",
                                                                    backgroundColor: isCorrect
                                                                        ? "var(--mantine-color-green-0)"
                                                                        : isUserAnswer
                                                                            ? "var(--mantine-color-red-0)"
                                                                            : "transparent",
                                                                },
                                                                label: {
                                                                    paddingLeft: "0.5rem",
                                                                },
                                                            }}
                                                        />
                                                    );
                                                })}
                                            </Stack>
                                        </Radio.Group>

                                        <Group gap="xs">
                                            {question.user_answer !== null && (
                                                <Badge
                                                    variant="light"
                                                    color={question.is_correct ? "green" : "red"}
                                                    leftSection={question.is_correct ? <IconCheck size={14} /> : <IconX size={14} />}
                                                >
                                                    {question.is_correct ? "정답" : "오답"}
                                                </Badge>
                                            )}
                                            {question.user_answer === null && (
                                                <Badge variant="light" color="gray">
                                                    미답
                                                </Badge>
                                            )}
                                        </Group>

                                        {question.explanation && (
                                            <Alert icon={<IconBook size={16} />} color="blue" variant="light">
                                                <Text size="sm" fw={500} mb="xs">
                                                    💡 해설
                                                </Text>
                                                <Text size="sm">{question.explanation}</Text>
                                            </Alert>
                                        )}
                                    </Stack>
                                </Accordion.Panel>
                            </Accordion.Item>
                        ))}
                    </Accordion>
                </Card>
            )}

            {/* Back to Dashboard */}
            <Group justify="center">
                <Button variant="subtle" component={Link} href="/dashboard">
                    대시보드로 돌아가기
                </Button>
            </Group>
        </Stack>
    );
}
