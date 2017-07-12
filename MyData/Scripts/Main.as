const float BALL_DIAMETER = 30.0f; // Диаметр шарика.
const Vector3 PLATFORM_SIZE = Vector3(120.0f, 10.0f, 60.f); // Размер платформы.

Scene@ scene_;     // Указатель на сцену.
Vector3 ballSpeed; // Текущая скорость шарика.
int score = 0;     // Текущий счет.

void Start()
{
    // Создаем новую сцену.
    scene_ = Scene();

    // Сцена является производным от ноды типом и к ней тоже можно
    // добавлять компоненты. Компонент Octree (октодерево) необходим,
    // если вы планируете отображать объекты сцены, то есть почти всегда.
    scene_.CreateComponent("Octree");

    // Создаем объекты в сцене.
    CreateZone();
    CreateBall();
    CreatePlatform();
    CreateCamera();

    // Создаем пользовательский интерфейс.
    CreateUI();

    // Определяем функцию, которая будет вызываться каждый кадр.
    SubscribeToEvent("Update", "HandleUpdate");

    // Приводим игру в начальное состояние.
    NewGame();
}

void CreateCamera()
{
    // Создаем для сцены дочернюю ноду и задаем ей имя MyCamera.
    // Имена нод можно использовать для того, чтобы искать нужный узел сцены.
    Node@ cameraNode = scene_.CreateChild("MyCamera");

    // Создаем камеру и прикрепляем ее к узлу.
    Camera@ camera = cameraNode.CreateComponent("Camera");
    camera.orthographic = true;

    // Координаты сцены будут соответствовать экранным пикселям.
    camera.orthoSize = graphics.height;

    // Указываем для узла с камерой положение в пространстве.
    // Координата X направлена слева направо, Y - снизу вверх, Z - от вас вглубь экрана.
    cameraNode.position = Vector3(0.0f, 0.0f, -200.0f);

    // Указываем движку какая камера какой сцены будет показана на экране.
    Viewport@ viewport = Viewport(scene_, camera);
    renderer.viewports[0] = viewport;
}

// Зона позволяет настраивать фоновое освещение, туман и фоновую текстуру.
void CreateZone()
{
    Node@ zoneNode = scene_.CreateChild("Zone");
    Zone@ zone = zoneNode.CreateComponent("Zone");

    // Задаем фоновое освещение внутри зоны.
    zone.ambientColor = Color(1.0f, 1.0f, 1.0f);

    // Увеличиваем размер зоны, чтобы она охватывала всю сцену.
    zone.boundingBox = BoundingBox(-1000.0f, 1000.0f);
}

// Создаёт шарик.
void CreateBall()
{
    // Создаем ноду для 3D-модели.
    Node@ ballNode = scene_.CreateChild("Ball");

    // Создаем компонент StaticModel - простая 3D-модель без скелета.
    StaticModel@ ballObject = ballNode.CreateComponent("StaticModel");

    // Загружаем модель из файла.
    ballObject.model = cache.GetResource("Model", "Models/Sphere.mdl");

    // Масштабируем шарик.
    ballNode.SetScale(BALL_DIAMETER);
}

// Создаёт платформу.
void CreatePlatform()
{
    Node@ platformNode = scene_.CreateChild("Platform");

    // Прикрепляем к ноде куб размером 1x1x1.
    StaticModel@ batBotObject = platformNode.CreateComponent("StaticModel");
    batBotObject.model = cache.GetResource("Model", "Models/Box.mdl");

    // Растягиваем куб до нужных размеров.
    platformNode.scale = PLATFORM_SIZE;
}

void CreateUI()
{
    // Создаем текстовый элемент для отображения счета.
    // UI не принадлежит сцене, сцена может вообще отсутствовать.
    Text@ scoreElement = ui.root.CreateChild("Text", "Score");
    scoreElement.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 60);
    scoreElement.position = IntVector2(12, 0);
}

// Апдейтим шарик каждый кадр. Здесь timeStep - время, прошедшее с прошлого кадра.
void UpdateBall(float timeStep)
{
    // Ищем шарик и платформу в сцене.
    Node@ ballNode = scene_.GetChild("Ball");
    Node@ platformNode = scene_.GetChild("Platform");

    // Если шарик касается левой или правой стороны экрана, то меняем его горизонтальную скорость.
    if (ballNode.position.x < -graphics.width / 2 + BALL_DIAMETER / 2)
        ballSpeed.x = Abs(ballSpeed.x);
    else if (ballNode.position.x > graphics.width / 2 - BALL_DIAMETER / 2)
        ballSpeed.x = -Abs(ballSpeed.x);

    // Если шарик касается верхней границы экрана, то меняем его вертикальную скорость.
    if (ballNode.position.y > graphics.height / 2 - BALL_DIAMETER / 2)
        ballSpeed.y = -Abs(ballSpeed.y);
    // Если шарик касается нижней стороны экрана,
    else if (ballNode.position.y < -graphics.height / 2 + BALL_DIAMETER / 2)
    {
        // и если платформа далеко от шарика,
        if (Abs(platformNode.position.x - ballNode.position.x) > PLATFORM_SIZE.x * 0.5f + BALL_DIAMETER * 0.5f)
        {
            // то начинаем игру заново.
            NewGame();
            return;
        }
        else
        {
            // Шарик отскакивает от платформы, увеличиваем счет.
            ballSpeed.y = Abs(ballSpeed.y);
            score++;

            // Обновляем UI-элемент, отображающий текущий счет.
            UpdateScoreElement();
        }
    }

    // Обновляем положение шарика с учетом текущей скорости.
    ballNode.position += ballSpeed * timeStep;
}

void NewGame()
{
    score = 0;
    InitBall();
    InitPlatform();
    UpdateScoreElement();
}

// Приводит шарик в начальное состояние.
void InitBall()
{
    // Ищем шарик в сцене.
    Node@ ballNode = scene_.GetChild("Ball");

    // Помещаем шарик в центр сцены. В нашем случае центр сцены совпадет
    // с центром экрана.
    ballNode.position = Vector3(0.0f, 0.0f, 0.0f);

    // Устанавливаем начальную скорость шарика.
    ballSpeed = Vector3(500.0f, 250.0f, 0.0f);
}

// Инициализирует платформу.
void InitPlatform()
{
    Node@ platformNode = scene_.GetChild("Platform");
    platformNode.position = Vector3(0.0f, -300.0f, 0.0f);
}

void UpdateScoreElement()
{
    Text@ scoreElement = ui.root.GetChild("Score");
    scoreElement.text = "Счёт: " + score;
}

void UpdatePlatform()
{
    // Смещение мыши с прошлого кадра.
    Vector3 delta = Vector3(input.mouseMoveX, 0.0f, 0.0f);

    Node@ platformNode = scene_.GetChild("Platform");
    platformNode.Translate(delta);
}

// Обработчик события Update.
void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Сколько времени прошло с предыдущего кадра.
    float timeStep = eventData["TimeStep"].GetFloat();

    UpdatePlatform();
    UpdateBall(timeStep);
}
