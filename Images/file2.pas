uses
  PngImage, SysUtils;

procedure PrintTransparency(Png: TPngImage; StartX, StartY, Width, Height: Integer; CornerName: string);
var
  x, y: Integer;
begin
  Writeln(CornerName, ':');
  for y := StartY to StartY + Height - 1 do
  begin
    for x := StartX to StartX + Width - 1 do
    begin
      Writeln('Пиксель (', x, ', ', y, ') - Прозрачность: ', Png.AlphaScanline[y]^[x]);
    end;
  end;
end;

procedure GetCornerTransparency(const FileName: string);
var
  Png: TPngImage;
  ImgWidth, ImgHeight: Integer;
  CornerSize: Integer;
begin
  Png := TPngImage.Create;
  try
    // Загружаем PNG изображение
    Png.LoadFromFile(FileName);
    
    // Проверяем наличие альфа-канала
    if not Png.TransparencyMode = ptmPartial then
    begin
      Writeln('Изображение не содержит прозрачности.');
      Exit;
    end;

    ImgWidth := Png.Width;
    ImgHeight := Png.Height;
    CornerSize := 8; // Размер угла 8x8 пикселей

    // Выводим прозрачность пикселей для каждого угла
    PrintTransparency(Png, 0, 0, CornerSize, CornerSize, 'Верхний левый угол');
    PrintTransparency(Png, ImgWidth - CornerSize, 0, CornerSize, CornerSize, 'Верхний правый угол');
    PrintTransparency(Png, 0, ImgHeight - CornerSize, CornerSize, CornerSize, 'Нижний левый угол');
    PrintTransparency(Png, ImgWidth - CornerSize, ImgHeight - CornerSize, CornerSize, CornerSize, 'Нижний правый угол');

  finally
    Png.Free;
  end;
end;

begin
  try
    GetCornerTransparency('your_image.png');
  except
    on E: Exception do
      Writeln('Ошибка: ', E.Message);
  end;
end.