"use client";

import { useState, useEffect, use } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import {
    Stack,
    Group,
    Button,
    Card,
    Text,
    Progress,
    Badge,
    Paper,
    Radio,
    Divider,
    Modal,
    SimpleGrid,
    ActionIcon,
    Alert,
    Center,
    Loader,
    Title,
} from "@mantine/core";
import {
    IconClock,
    IconChevronLeft,
    IconChevronRight,
    IconCheck,
    IconAlertCircle,
    IconFlag,
} from "@tabler/icons-react";
import { notifications } from "@mantine/notifications";

interface Question {
    id: string;
    question_text: string;
    options: string[];
    passage?: string;
    original_index?: number;
}

interface TestSession {
    session_id: string;
    questions: Question[];
    total_questions: number;
    time_limit_minutes?: number;
    started_at: string;
}

interface Answer {
    question_id: string;
    selected_option: number;
}

export default function TestSessionPage({ params }: { params: Promise<{ sessionId: string }> }) {
    const resolvedParams = use(params);
    const router = useRouter();
    const { getToken } = useAuth();

    const [session, setSession] = useState<TestSession | null>(null);
    const [loading, setLoading] = useState(true);
    const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
    const [answers, setAnswers] = useState<Map<string, number>>(new Map());
    const [flagged, setFlagged] = useState<Set<string>>(new Set());
    const [timeRemaining, setTimeRemaining] = useState<number | null>(null);
    const [submitModalOpen, setSubmitModalOpen] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        fetchSession();
    }, []);

    useEffect(() => {
        if (!session?.time_limit_minutes) return;

        const startTime = new Date(session.started_at).getTime();
        const endTime = startTime + session.time_limit_minutes * 60 * 1000;

        const interval = setInterval(() => {
            const now = Date.now();
            const remaining = Math.max(0, Math.floor((endTime - now) / 1000));
            setTimeRemaining(remaining);

            if (remaining === 0) {
                notifications.show({
                    title: "시간 종료",
                    message: "제한 시간이 종료되어 자동으로 제출됩니다",
                    color: "red",
                });
                handleSubmit();
            }
        }, 1000);

        return () => clearInterval(interval);
    }, [session]);

    const fetchSession = async () => {
        try {
            const token = await getToken();
            if (!token) return;

            const response = await fetch(
                `${process.env.NEXT_PUBLIC_API_URL}/tests/${resolvedParams.sessionId}`,
                {
                    headers: { Authorization: `Bearer ${token}` },
                }
            );

            if (!response.ok) {
                throw new Error("세션을 불러올 수 없습니다");
            }

            const data = await response.json();
            setSession(data.data);
        } catch (error: any) {
            console.error("Failed to fetch session:", error);
            notifications.show({
                title: "오류",
                message: error.message,
                color: "red",
            });
            router.push("/dashboard/test");
        } finally {
            setLoading(false);
        }
    };

    const handleAnswerSelect = (questionId: string, optionIndex: number) => {
        setAnswers(new Map(answers.set(questionId, optionIndex)));
    };

    const toggleFlag = (questionId: string) => {
        const newFlagged = new Set(flagged);
        if (newFlagged.has(questionId)) {
            newFlagged.delete(questionId);
        } else {
            newFlagged.add(questionId);
        }
        setFlagged(newFlagged);
    };

    const handleSubmit = async () => {
        if (submitting) return;
        setSubmitting(true);

        try {
            const token = await getToken();
            if (!token) throw new Error("인증 토큰이 없습니다");

            const answersList: Answer[] = Array.from(answers.entries()).map(
                ([question_id, selected_option]) => ({
                    question_id,
                    selected_option,
                })
            );

            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/tests/submit`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    session_id: resolvedParams.sessionId,
                    answers: answersList,
                }),
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.error?.message || "제출 실패");
            }

            notifications.show({
                title: "제출 완료!",
                message: "채점 결과를 확인하세요",
                color: "green",
            });

            router.push(`/dashboard/test/result/${resolvedParams.sessionId}`);
        } catch (error: any) {
            console.error("Failed to submit:", error);
            notifications.show({
                title: "제출 실패",
                message: error.message,
                color: "red",
            });
        } finally {
            setSubmitting(false);
            setSubmitModalOpen(false);
        }
    };

    if (loading || !session) {
        return (
            <Center h={400}>
                <Loader size="lg" />
            </Center>
        );
    }

    const currentQuestion = session.questions[currentQuestionIndex];
    const progress = (answers.size / session.total_questions) * 100;
    const unansweredCount = session.total_questions - answers.size;

    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, "0")}`;
    };

    return (
        <Stack gap="md" maw={1000} mx="auto">
            {/* Header */}
            <Paper p="md" radius="md" withBorder>
                <Group justify="space-between">
                    <div>
                        <Text size="sm" c="dimmed">
                            모의고사 진행 중
                        </Text>
                        <Text size="lg" fw={600}>
                            문제 {currentQuestionIndex + 1} / {session.total_questions}
                        </Text>
                    </div>

                    <Group>
                        {timeRemaining !== null && (
                            <Badge
                                size="lg"
                                variant="light"
                                color={timeRemaining < 300 ? "red" : "blue"}
                                leftSection={<IconClock size={14} />}
                            >
                                {formatTime(timeRemaining)}
                            </Badge>
                        )}
                        <Badge size="lg" variant="light" color="green">
                            {answers.size} / {session.total_questions} 완료
                        </Badge>
                    </Group>
                </Group>

                <Progress value={progress} size="sm" mt="md" />
            </Paper>

            {/* Question Content */}
            <Card shadow="sm" padding="xl" radius="md">
                <Stack gap="xl">
                    {/* Passage (if exists) */}
                    {currentQuestion.passage && (
                        <Paper p="md" radius="md" style={{ backgroundColor: "var(--mantine-color-gray-0)" }}>
                            <Text size="sm" fw={500} mb="xs" c="dimmed">
                                📄 지문
                            </Text>
                            <Text size="sm" style={{ whiteSpace: "pre-wrap" }}>
                                {currentQuestion.passage}
                            </Text>
                        </Paper>
                    )}

                    {/* Question */}
                    <div>
                        <Group justify="space-between" mb="md">
                            <Text size="lg" fw={600}>
                                Q{currentQuestionIndex + 1}. {currentQuestion.question_text}
                            </Text>
                            <ActionIcon
                                variant={flagged.has(currentQuestion.id) ? "filled" : "light"}
                                color="orange"
                                size="lg"
                                onClick={() => toggleFlag(currentQuestion.id)}
                            >
                                <IconFlag size={18} />
                            </ActionIcon>
                        </Group>

                        {/* Options */}
                        <Radio.Group
                            value={answers.get(currentQuestion.id)?.toString()}
                            onChange={(value) => handleAnswerSelect(currentQuestion.id, parseInt(value))}
                        >
                            <Stack gap="sm">
                                {currentQuestion.options.map((option, index) => (
                                    <Radio
                                        key={index}
                                        value={index.toString()}
                                        label={
                                            <Text size="md" style={{ whiteSpace: "pre-wrap" }}>
                                                {option}
                                            </Text>
                                        }
                                        styles={{
                                            root: {
                                                padding: "1rem",
                                                borderRadius: "var(--mantine-radius-md)",
                                                border: "1px solid var(--mantine-color-gray-3)",
                                                "&:has(input:checked)": {
                                                    backgroundColor: "var(--mantine-color-blue-0)",
                                                    borderColor: "var(--mantine-color-blue-6)",
                                                },
                                            },
                                            label: {
                                                cursor: "pointer",
                                                paddingLeft: "0.5rem",
                                            },
                                        }}
                                    />
                                ))}
                            </Stack>
                        </Radio.Group>
                    </div>
                </Stack>
            </Card>

            {/* Navigation */}
            <Group justify="space-between">
                <Button
                    variant="light"
                    leftSection={<IconChevronLeft size={18} />}
                    onClick={() => setCurrentQuestionIndex((prev) => Math.max(0, prev - 1))}
                    disabled={currentQuestionIndex === 0}
                >
                    이전 문제
                </Button>

                <Group>
                    <Button
                        variant="light"
                        color="orange"
                        onClick={() => setSubmitModalOpen(true)}
                    >
                        제출하기
                    </Button>

                    <Button
                        rightSection={<IconChevronRight size={18} />}
                        onClick={() =>
                            setCurrentQuestionIndex((prev) => Math.min(session.total_questions - 1, prev + 1))
                        }
                        disabled={currentQuestionIndex === session.total_questions - 1}
                    >
                        다음 문제
                    </Button>
                </Group>
            </Group>

            {/* Question Navigator */}
            <Card shadow="sm" padding="md" radius="md">
                <Text size="sm" fw={500} mb="md">
                    문제 번호
                </Text>
                <SimpleGrid cols={{ base: 10, sm: 15, md: 20 }} spacing="xs">
                    {session.questions.map((q, index) => {
                        const isAnswered = answers.has(q.id);
                        const isFlagged = flagged.has(q.id);
                        const isCurrent = index === currentQuestionIndex;

                        return (
                            <Button
                                key={q.id}
                                variant={isCurrent ? "filled" : isAnswered ? "light" : "default"}
                                color={isFlagged ? "orange" : isAnswered ? "green" : "gray"}
                                size="sm"
                                onClick={() => setCurrentQuestionIndex(index)}
                                styles={{
                                    root: {
                                        padding: "0.25rem",
                                        minWidth: "2rem",
                                        height: "2rem",
                                    },
                                }}
                            >
                                {index + 1}
                            </Button>
                        );
                    })}
                </SimpleGrid>

                <Divider my="md" />

                <Group gap="md">
                    <Group gap="xs">
                        <Badge variant="light" color="green" leftSection={<IconCheck size={14} />}>
                            답변 완료: {answers.size}
                        </Badge>
                        <Badge variant="light" color="gray">
                            미답변: {unansweredCount}
                        </Badge>
                        <Badge variant="light" color="orange" leftSection={<IconFlag size={14} />}>
                            표시: {flagged.size}
                        </Badge>
                    </Group>
                </Group>
            </Card>

            {/* Submit Confirmation Modal */}
            <Modal
                opened={submitModalOpen}
                onClose={() => setSubmitModalOpen(false)}
                title={<Text fw={600}>시험 제출</Text>}
                centered
            >
                <Stack gap="md">
                    {unansweredCount > 0 && (
                        <Alert icon={<IconAlertCircle size={16} />} color="orange" variant="light">
                            <Text size="sm">
                                답변하지 않은 문제가 {unansweredCount}개 있습니다.
                            </Text>
                        </Alert>
                    )}

                    <Text size="sm">
                        제출하시겠습니까? 제출 후에는 답안을 수정할 수 없습니다.
                    </Text>

                    <Group justify="flex-end">
                        <Button variant="light" onClick={() => setSubmitModalOpen(false)}>
                            취소
                        </Button>
                        <Button onClick={handleSubmit} loading={submitting}>
                            제출하기
                        </Button>
                    </Group>
                </Stack>
            </Modal>
        </Stack>
    );
}
