Перед запуском необходимо создать tasks.json в корне проекта. Пример содержимого файла:
```json
{
  "periodic": [{"id": 1, "period": 96899, "exec_time": 758}, {"id": 2, "period": 63384, "exec_time": 275}, {"id": 3, "period": 80497, "exec_time": 406}, {"id": 4, "period": 45346, "exec_time": 630}, {"id": 5, "period": 87180, "exec_time": 1145}],
  "aperiodic": [{"id": 40, "period": 51188, "exec_time": 1831}, {"id": 41, "period": 47113, "exec_time": 1593}, {"id": 42, "period": 91777, "exec_time": 396}, {"id": 43, "period": 98283, "exec_time": 1476}, {"id": 44, "period": 35101, "exec_time": 615}, {"id": 45, "period": 41348, "exec_time": 1641}, {"id": 46, "period": 50201, "exec_time": 1088}, {"id": 47, "period": 67920, "exec_time": 555}, {"id": 48, "period": 55377, "exec_time": 404}, {"id": 49, "period": 50834, "exec_time": 974}, {"id": 50, "period": 78815, "exec_time": 1933}, {"id": 51, "period": 43526, "exec_time": 1155}, {"id": 52, "period": 30246, "exec_time": 1245}, {"id": 53, "period": 85844, "exec_time": 873}, {"id": 54, "period": 98815, "exec_time": 519}, {"id": 55, "period": 96579, "exec_time": 1736}, {"id": 56, "period": 80944, "exec_time": 1907}, {"id": 57, "period": 79729, "exec_time": 410}, {"id": 58, "period": 37591, "exec_time": 321}, {"id": 59, "period": 77885, "exec_time": 330}, {"id": 60, "period": 72549, "exec_time": 871}]
}
```
:warning: Период и время исполнения **ДОЛЖНЫ** быть представлены в миллисекундах

После GET-обращения по /rm или /edf необходимо проверить logs/ директорию, в которой должны находиться пронумерованные ОЫЩТ-файлы 4 гиперпериодов и файл со статистикой по выбранному алгоритму (среднее время отклика, макс. время отклика)


Порядок команд для запуска:

1. Генерация задач => ruby lib/tasks_generator.rb (выдает tasks_i.json)   :warning:  Следить за const в lib/tasks_generator.rb
2. Запускаем ruby main.rb (переходим на localhost:3000)
3. localhost:3000/метод/ид (выдает файлы в папке logs: rm_stats.json, rm1.json, ....)


4. Перейти во freecad, прописать команду: exec(open("D:/_KolyaN/4-kurs-2-sem/Real-time Systems/Egor_proga/srv3/freecad.py").read())   :warning:  Следить за const в freecad.py
5. Экспорт чертежа в dxf.

- Посчитать гиперпериод и фрейм. => Запуск ruby lib/hyperperiod_and_frame.rb    :warning:  Следить за const в lib/hyperperiod_and_frame.rb
