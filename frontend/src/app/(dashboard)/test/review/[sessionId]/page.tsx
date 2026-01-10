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
    Paper,
    Radio,
    Alert,
    Center,
    Loader,
    Divider,
    ThemeIcon,
    Progress,
    Textarea,
    TextInput,
    Modal,
    Checkbox,
} from "@mantine/core";
import {
    IconX,
    IconCheck,
    IconBook,
    IconChevronLeft,
    IconChevronRight,
    IconAlertCircle,
    IconHome,
    IconTag,
    IconNote,
    IconRefresh,
} from "@tabler/icons-react";
import Link from "next/link";

interface WrongQuestion {
    question_id: string;
    question_text: string;
    options: string[];
    user_answer: number | null;
    correct_answer: number;
    explanation?: string;
    passage?: string;
    tags?: string[];
    memo?: string;
    completed?: boolean;
}

interface ReviewData {
    session_id: string;
    study_set_name: string;
    wrong_questions: WrongQuestion[];
    total_wrong: number;
}

export default function TestReviewPage({ params }: { params: Promise<{ sessionId: string }> }) {
    const resolvedParams = use(params);
    const router = useRouter();
    const { getToken } = useAuth();
    const [reviewData, setReviewData] = useState<ReviewData | null>(null);
    const [loading, setLoading] = useState(true);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [understood, setUnderstood] = useState<Set<string>>(new Set());

    // 태그 및 메모 관련 상태
    const [tagModalOpen, setTagModalOpen] = useState(false);
    const [memoModalOpen, setMemoModalOpen] = useState(false);
    const [currentTags, setCurrentTags] = useState<string>("");
    const [currentMemo, setCurrentMemo] = useState<string>("");

    useEffect(() => {
        fetchReviewData();
    }, []);

    const fetchReviewData = async () => {
        try {
            const token = await getToken();
            if (!token) return;

            // Fetch full result and filter wrong questions
            const response = await fetch(
                `${process.env.NEXT_PUBLIC_API_URL}/tests/${resolvedParams.sessionId}/result`,
                {
                    headers: { Authorization: `Bearer ${token}` },
                }
            );

            if (!response.ok) {
                throw new Error("데이터를 불러올 수 없습니다");
            }

            const data = await response.json();
            const result = data.data;

            const wrongQuestions = result.questions.filter((q: any) => !q.is_correct).map((q: any) => ({
                ...q,
                tags: [],
                memo: "",
                completed: false,
            }));

            setReviewData({
                session_id: resolvedParams.sessionId,
                study_set_name: result.study_set_name,
                wrong_questions: wrongQuestions,
                total_wrong: wrongQuestions.length,
            });
        } catch (error: any) {
            console.error("Failed to fetch review data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleUnderstood = (questionId: string) => {
        setUnderstood(new Set(understood.add(questionId)));
    };

    const handleRetake = () => {
        // 다시 풀기 기능 - 새로운 테스트 세션 시작
        router.push(`/dashboard/test/start?mode=wrong&sessionId=${resolvedParams.sessionId}`);
    };

    const handleAddTags = () => {
        if (!reviewData) return;
        const currentQuestion = reviewData.wrong_questions[currentIndex];
        setCurrentTags(currentQuestion.tags?.join(", ") || "");
        setTagModalOpen(true);
    };

    const handleSaveTags = () => {
        if (!reviewData) return;
        const tags = currentTags.split(",").map(t => t.trim()).filter(t => t);
        const updatedQuestions = [...reviewData.wrong_questions];
        updatedQuestions[currentIndex].tags = tags;
        setReviewData({ ...reviewData, wrong_questions: updatedQuestions });
        setTagModalOpen(false);
    };

    const handleAddMemo = () => {
        if (!reviewData) return;
        const currentQuestion = reviewData.wrong_questions[currentIndex];
        setCurrentMemo(currentQuestion.memo || "");
        setMemoModalOpen(true);
    };

    const handleSaveMemo = () => {
        if (!reviewData) return;
        const updatedQuestions = [...reviewData.wrong_questions];
        updatedQuestions[currentIndex].memo = currentMemo;
        setReviewData({ ...reviewData, wrong_questions: updatedQuestions });
        setMemoModalOpen(false);
    };

    const handleToggleComplete = (questionId: string) => {
        if (!reviewData) return;
        const updatedQuestions = reviewData.wrong_questions.map(q =>
            q.question_id === questionId ? { ...q, completed: !q.completed } : q
        );
        setReviewData({ ...reviewData, wrong_questions: updatedQuestions });
    };

    if (loading || !reviewData) {
        return (
            <Center h={400}>
                <Loader size="lg" />
            </Center>
        );
    }

    if (reviewData.total_wrong === 0) {
        return (
            <Stack gap="xl" maw={800} mx="auto">
                <Alert icon={<IconCheck size={16} />} color="green" variant="light">
                    <Stack gap="sm">
                        <Text size="lg" fw={600}>
                            🎉 완벽합니다!
                        </Text>
                        <Text size="sm">
                            틀린 문제가 없습니다. 모든 문제를 정답으로 맞추셨습니다!
                        </Text>
                        <Button
                            component={Link}
                            href="/dashboard"
                            variant="light"
                            leftSection={<IconHome size={18} />}
                        >
                            대시보드로 돌아가기
                        </Button>
                    </Stack>
                </Alert>
            </Stack>
        );
    }

    const currentQuestion = reviewData.wrong_questions[currentIndex];
    const progress = ((currentIndex + 1) / reviewData.total_wrong) * 100;
    const understoodCount = understood.size;
    const completedCount = reviewData.wrong_questions.filter(q => q.completed).length;

    return (
        <Stack gap="md" maw={1000} mx="auto">
            {/* Header */}
            <Paper p="md" radius="md" withBorder>
                <Group justify="space-between">
                    <div>
                        <Text size="sm" c="dimmed">
                            오답 노트
                        </Text>
                        <Text size="lg" fw={600}>
                            {reviewData.study_set_name}
                        </Text>
                    </div>

                    <Group>
                        <Badge size="lg" variant="light" color="red">
                            오답 {currentIndex + 1} / {reviewData.total_wrong}
                        </Badge>
                        <Badge size="lg" variant="light" color="green">
                            이해 완료: {understoodCount}
                        </Badge>
                    </Group>
                </Group>

                <Progress value={progress} size="sm" mt="md" color="red" />

                {/* 다시 풀기 버튼 */}
                <Group mt="md">
                    <Button
                        variant="light"
                        leftSection={<IconRefresh size={18} />}
                        onClick={handleRetake}
                    >
                        다시 풀기
                    </Button>
                </Group>
            </Paper>

            {/* Question Card */}
            <Card shadow="md" padding="xl" radius="lg" className={`review-question ${currentQuestion.completed ? 'completed' : ''}`}>
                <Stack gap="xl">
                    {/* Alert */}
                    <Alert icon={<IconAlertCircle size={16} />} color="red" variant="light">
                        <Text size="sm">
                            이 문제를 틀렸습니다. 해설을 읽고 개념을 다시 확인하세요.
                        </Text>
                    </Alert>

                    {/* Passage */}
                    {currentQuestion.passage && (
                        <Paper p="md" radius="md" bg="gray.0">
                            <Text size="xs" fw={500} c="dimmed" mb="xs">
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
                            <Text size="xl" fw={600}>
                                Q{currentIndex + 1}. {currentQuestion.question_text}
                            </Text>

                            {/* 완료 체크박스 */}
                            <Checkbox
                                label="완료"
                                checked={currentQuestion.completed || false}
                                onChange={() => handleToggleComplete(currentQuestion.question_id)}
                            />
                        </Group>

                        {/* Options */}
                        <Radio.Group value={currentQuestion.correct_answer.toString()}>
                            <Stack gap="sm">
                                {currentQuestion.options.map((option, optIndex) => {
                                    const isUserAnswer = currentQuestion.user_answer === optIndex;
                                    const isCorrect = currentQuestion.correct_answer === optIndex;

                                    return (
                                        <Paper
                                            key={optIndex}
                                            p="md"
                                            radius="md"
                                            withBorder
                                            style={{
                                                borderWidth: 2,
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
                                            }}
                                        >
                                            <Group justify="space-between">
                                                <Text size="md" style={{ whiteSpace: "pre-wrap", flex: 1 }}>
                                                    {option}
                                                </Text>
                                                {isCorrect && (
                                                    <ThemeIcon color="green" variant="light" size="sm">
                                                        <IconCheck size={14} />
                                                    </ThemeIcon>
                                                )}
                                                {isUserAnswer && !isCorrect && (
                                                    <ThemeIcon color="red" variant="light" size="sm">
                                                        <IconX size={14} />
                                                    </ThemeIcon>
                                                )}
                                            </Group>
                                        </Paper>
                                    );
                                })}
                            </Stack>
                        </Radio.Group>

                        {/* Answer Info */}
                        <Group gap="md" mt="lg">
                            {currentQuestion.user_answer !== null ? (
                                <Badge variant="light" color="red" size="lg" leftSection={<IconX size={14} />}>
                                    내 답: {currentQuestion.user_answer + 1}번
                                </Badge>
                            ) : (
                                <Badge variant="light" color="gray" size="lg">
                                    미답
                                </Badge>
                            )}
                            <Badge variant="light" color="green" size="lg" leftSection={<IconCheck size={14} />}>
                                정답: {currentQuestion.correct_answer + 1}번
                            </Badge>
                        </Group>
                    </div>

                    <Divider />

                    {/* Explanation */}
                    {currentQuestion.explanation ? (
                        <Alert icon={<IconBook size={16} />} color="blue" variant="light">
                            <Text size="sm" fw={600} mb="xs">
                                💡 해설
                            </Text>
                            <Text size="sm" style={{ whiteSpace: "pre-wrap" }}>
                                {currentQuestion.explanation}
                            </Text>
                        </Alert>
                    ) : (
                        <Alert icon={<IconAlertCircle size={16} />} color="gray" variant="light">
                            <Text size="sm">해설이 제공되지 않습니다.</Text>
                        </Alert>
                    )}

                    {/* Tags */}
                    {currentQuestion.tags && currentQuestion.tags.length > 0 && (
                        <Group gap="xs">
                            {currentQuestion.tags.map((tag, idx) => (
                                <Badge key={idx} className="tag" variant="light" color="blue">
                                    {tag}
                                </Badge>
                            ))}
                        </Group>
                    )}

                    {/* Memo Indicator */}
                    {currentQuestion.memo && (
                        <Alert icon={<IconNote size={16} />} color="yellow" variant="light" className="memo-indicator">
                            <Text size="sm" fw={600} mb="xs">
                                📝 내 메모
                            </Text>
                            <Text size="sm" style={{ whiteSpace: "pre-wrap" }}>
                                {currentQuestion.memo}
                            </Text>
                        </Alert>
                    )}

                    {/* Action Buttons */}
                    <Group>
                        {!understood.has(currentQuestion.question_id) && (
                            <Button
                                variant="light"
                                color="green"
                                leftSection={<IconCheck size={18} />}
                                onClick={() => handleUnderstood(currentQuestion.question_id)}
                            >
                                이해했어요!
                            </Button>
                        )}

                        <Button
                            variant="light"
                            color="blue"
                            leftSection={<IconTag size={18} />}
                            onClick={handleAddTags}
                        >
                            태그 추가
                        </Button>

                        <Button
                            variant="light"
                            color="yellow"
                            leftSection={<IconNote size={18} />}
                            onClick={handleAddMemo}
                        >
                            메모
                        </Button>
                    </Group>
                </Stack>
            </Card>

            {/* Navigation */}
            <Group justify="space-between">
                <Button
                    variant="light"
                    leftSection={<IconChevronLeft size={18} />}
                    onClick={() => setCurrentIndex((prev) => Math.max(0, prev - 1))}
                    disabled={currentIndex === 0}
                >
                    이전 문제
                </Button>

                {currentIndex < reviewData.total_wrong - 1 ? (
                    <Button
                        rightSection={<IconChevronRight size={18} />}
                        onClick={() => setCurrentIndex((prev) => prev + 1)}
                    >
                        다음 문제
                    </Button>
                ) : (
                    <Button
                        component={Link}
                        href={`/dashboard/test/result/${resolvedParams.sessionId}`}
                        rightSection={<IconChevronRight size={18} />}
                        color="green"
                    >
                        결과로 돌아가기
                    </Button>
                )}
            </Group>

            {/* Progress Summary */}
            <Paper p="md" radius="md" withBorder>
                <Group justify="space-between">
                    <Text size="sm" c="dimmed" className="review-progress">
                        복습 진행률: {completedCount} 완료
                    </Text>
                    <Text size="sm" fw={600}>
                        {Math.round(progress)}%
                    </Text>
                </Group>
                <Progress value={progress} size="lg" mt="xs" color="red" />

                <Divider my="md" />

                <Group justify="space-between">
                    <Group gap="md">
                        <Badge variant="light" color="red">
                            총 {reviewData.total_wrong}개
                        </Badge>
                        <Badge variant="light" color="green">
                            이해 {understoodCount}개
                        </Badge>
                        <Badge variant="light" color="blue">
                            완료 {completedCount}개
                        </Badge>
                        <Badge variant="light" color="gray">
                            남음 {reviewData.total_wrong - completedCount}개
                        </Badge>
                    </Group>

                    <Button
                        variant="subtle"
                        size="sm"
                        component={Link}
                        href="/dashboard"
                        leftSection={<IconHome size={16} />}
                    >
                        대시보드
                    </Button>
                </Group>
            </Paper>

            {/* Tag Modal */}
            <Modal
                opened={tagModalOpen}
                onClose={() => setTagModalOpen(false)}
                title="태그 추가"
            >
                <Stack>
                    <TextInput
                        className="tag-input"
                        label="태그 (쉼표로 구분)"
                        placeholder="실수, 개념부족"
                        value={currentTags}
                        onChange={(e) => setCurrentTags(e.target.value)}
                    />
                    <Button onClick={handleSaveTags}>저장</Button>
                </Stack>
            </Modal>

            {/* Memo Modal */}
            <Modal
                opened={memoModalOpen}
                onClose={() => setMemoModalOpen(false)}
                title="메모 작성"
            >
                <Stack>
                    <Textarea
                        className="memo-textarea"
                        label="메모"
                        placeholder="다음번에는 문제를 더 꼼꼼히 읽자"
                        value={currentMemo}
                        onChange={(e) => setCurrentMemo(e.target.value)}
                        minRows={4}
                    />
                    <Button onClick={handleSaveMemo}>메모 저장</Button>
                </Stack>
            </Modal>
        </Stack>
    );
}
