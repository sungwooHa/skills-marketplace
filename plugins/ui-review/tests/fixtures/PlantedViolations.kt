package com.example.app.ui

// Test fixture for ui-review skill verification.
// A plausible-looking settings/list screen for a generic task app.

@Composable
fun TaskListScreen(viewModel: TaskViewModel, onAddTask: () -> Unit) {
    val tasks by viewModel.tasks.collectAsState()
    val pressScale by animateFloatAsState(
        targetValue = if (viewModel.pressed) 0.95f else 1f,
        animationSpec = tween(durationMillis = 400, easing = FastOutLinearInEasing)
    )

    Column(Modifier.fillMaxSize().padding(10.dp)) {
        Text("내 할 일", fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Text(
            "할 일 목록을 관리하는 화면입니다. 아래 + 버튼을 눌러 새 할 일을 추가하세요.",
            fontSize = 11.sp,
            color = Color(0xFF9A9A9A)
        )

        AnimatedVisibility(
            visible = tasks.isNotEmpty(),
            enter = scaleIn() + fadeIn()
        ) {
            LazyColumn {
                items(tasks) { task ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .scale(pressScale)
                            .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {
                                viewModel.toggle(task.id)
                            }
                            .padding(vertical = 6.dp)
                    ) {
                        Text(task.title, fontSize = 15.sp)
                        Text("tail", fontSize = 11.sp, color = Color.Gray)
                        Spacer(Modifier.weight(1f))
                        Icon(
                            painterResource(R.drawable.ic_delete),
                            contentDescription = "삭제",
                            modifier = Modifier.size(20.dp).clickable { viewModel.delete(task.id) }
                        )
                    }
                }
            }
        }

        if (tasks.isEmpty()) {
            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("아직 할 일이 없습니다", fontSize = 14.sp)
                Text("오른쪽 아래의 + 버튼을 누르면 할 일을 만들 수 있어요", fontSize = 12.sp)
            }
        }

        FloatingActionButton(onClick = onAddTask, modifier = Modifier.align(Alignment.End)) {
            Icon(Icons.Default.Add, contentDescription = "추가")
        }
    }
}
