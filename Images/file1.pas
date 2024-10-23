uses
  PngImage, SysUtils;

function GetAverageTransparency(Png: TPngImage; StartX, StartY, Width, Height: Integer): Byte;
var
  x, y: Integer;
  AlphaSum: LongInt;
  PixelCount: Integer;
begin
  AlphaSum := 0;
  PixelCount := 0;

  // Перебираем пиксели в заданной области
  for y := StartY to StartY + Height - 1 do
  begin
    for x := StartX to StartX + Width - 1 do
    begin
      AlphaSum := AlphaSum + Png.AlphaScanline[y]^[x];
      Inc(PixelCount);
    end;
  end;

  // Возвращаем среднее значение альфа-прозрачности
  Result := AlphaSum div PixelCount;
end;

procedure GetCornerTransparency(const FileName: string);
var
  Png: TPngImage;
  ImgWidth, ImgHeight: Integer;
  AlphaTopLeft, AlphaTopRight, AlphaBottomLeft, AlphaBottomRight: Byte;
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

    // Получаем среднее значение прозрачности в четырех углах
    AlphaTopLeft := GetAverageTransparency(Png, 0, 0, CornerSize, CornerSize);
    AlphaTopRight := GetAverageTransparency(Png, ImgWidth - CornerSize, 0, CornerSize, CornerSize);
    AlphaBottomLeft := GetAverageTransparency(Png, 0, ImgHeight - CornerSize, CornerSize, CornerSize);
    AlphaBottomRight := GetAverageTransparency(Png, ImgWidth - CornerSize, ImgHeight - CornerSize, CornerSize, CornerSize);

    // Выводим значения прозрачности
    Writeln('Средняя прозрачность (верхний левый угол): ', AlphaTopLeft);
    Writeln('Средняя прозрачность (верхний правый угол): ', AlphaTopRight);
    Writeln('Средняя прозрачность (нижний левый угол): ', AlphaBottomLeft);
    Writeln('Средняя прозрачность (нижний правый угол): ', AlphaBottomRight);
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
