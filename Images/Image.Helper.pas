unit ImageHelper;

interface

uses
  SysUtils, Classes, Windows, Graphics, PNGImage, JPEG, ExtCtrls, DB, SqlExpr, Dialogs, ImageFormat;

  function GetImageFormatFromBlob(BlobField: TBlobField): TImageFormat; overload;
  function IsWhiteBackground(PNG: TPngImage): Boolean;
  function HasTransparentBackground(PNG: TPngImage): Boolean;
  function GetAlphaBackgroundColor(const Png: TPngImage): TColor;

  function ConvertBitmapToPng(Bitmap: TBitmap): TPngImage;
  function SavePictureToStream(Picture: TPicture; Stream: TStream): Boolean;
  function ExtractImageFormat(Picture: TPicture): TImageFormat;
  procedure GetGraphicType(Picture: TPicture);

implementation

function GetImageFormatFromBlob(BlobField: TBlobField): TImageFormat;
var
  MemoryStream: TMemoryStream;
begin
  MemoryStream := TMemoryStream.Create;
  try
    BlobField.SaveToStream(MemoryStream);
    MemoryStream.Position := 0;
    Result := GetImageFormatFromStream(MemoryStream);
  finally
    MemoryStream.Free;
  end;
end;

function IsWhiteBackground(PNG: TPngImage): Boolean;
var
  x, y: Integer;
  PixelColor: TColor;
begin
  Result := True;

  for y := 0 to PNG.Height - 1 do
  begin
    for x := 0 to PNG.Width - 1 do
    begin
      PixelColor := PNG.Pixels[x, y];
      // If at least one pixel is not white, the background is not white
      if PixelColor <> clWhite then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

function HasTransparentBackground(PNG: TPngImage): Boolean;
var
  x, y: Integer;
begin
  Result := False;

  // Checking if there is an alpha channel
  if PNG.Header.ColorType = COLOR_GRAYSCALEALPHA or COLOR_RGBALPHA then
  begin
    for y := 0 to PNG.Height - 1 do
    begin
      for x := 0 to PNG.Width - 1 do
      begin
        // If the alpha channel is less than 255, then there is transparency.
        if PNG.AlphaScanline[y]^[x] < 255 then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

function GetAlphaBackgroundColor(const Png: TPngImage): TColor;
var
  x, y: Integer;
  TransparentPixelCount: Integer;
  TotalR, TotalG, TotalB: Integer;
  PixelColor: TColor;
  AlphaValue: Byte;
begin
  // Инициализируем переменные для подсчета
  TotalR := 0;
  TotalG := 0;
  TotalB := 0;
  TransparentPixelCount := 0;

  // Проверяем, есть ли альфа-канал
  if Png.TransparencyMode = ptmPartial then
  begin
    // Проходим по каждому пикселю
    for y := 0 to Png.Height - 1 do
    begin
      for x := 0 to Png.Width - 1 do
      begin
        // Получаем цвет пикселя
        PixelColor := Png.Pixels[x, y];

        // Получаем альфа-канал (если он есть)
        AlphaValue := Png.AlphaScanline[y]^[x];

        // Если альфа-канал равен 0 (полностью прозрачный)
        if AlphaValue = 0 then
        begin
          Inc(TotalR, GetRValue(PixelColor));
          Inc(TotalG, GetGValue(PixelColor));
          Inc(TotalB, GetBValue(PixelColor));

          Inc(TransparentPixelCount);
        end;
      end;
    end;
  end;

  // Если прозрачные пиксели были найдены
  if TransparentPixelCount > 0 then
  begin
    // Вычисляем средний цвет для прозрачных пикселей
    Result := RGB(
      TotalR div TransparentPixelCount,
      TotalG div TransparentPixelCount,
      TotalB div TransparentPixelCount
    );
  end
  else
  begin
    // Если нет прозрачных пикселей, возвращаем белый цвет
    Result := clWhite;
  end;
end;

function ConvertBitmapToPng(Bitmap: TBitmap): TPngImage;
var
  PNG: TPngImage;
begin
  PNG := TPngImage.Create;
  try
    PNG.Assign(Bitmap);
    Result := PNG;
  except
    PNG.Free;
    raise;
  end;
end;

function ExtractBitmapFromImage(Image: TImage): TBitmap;
begin
  Result := TBitmap.Create;
  try
    if Assigned(Image.Picture.Graphic) and (Image.Picture.Graphic is TBitmap) then
    begin
      Result.Assign(Image.Picture.Bitmap);
    end
    else
    begin
      Result.Assign(Image.Picture.Graphic);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function SavePictureToStream(Picture: TPicture; Stream: TStream): Boolean;
begin
  Result := False;  // По умолчанию возвращаем False
  if Assigned(Picture) and Assigned(Picture.Graphic) then
  begin
    // Определяем формат изображения и записываем в поток
    if Picture.Graphic is TBitmap then
    begin
      // Сохраняем Bitmap в поток
      TBitmap(Picture.Graphic).SaveToStream(Stream);
      Result := True;
    end
    else if Picture.Graphic is TJPEGImage then
    begin
      // Сохраняем JPEG в поток
      TJPEGImage(Picture.Graphic).SaveToStream(Stream);
      Result := True;
    end
    else if Picture.Graphic is TPngImage then
    begin
      // Сохраняем PNG в поток
      TPngImage(Picture.Graphic).SaveToStream(Stream);
      Result := True;
    end
    else
    begin
      raise Exception.Create('Unsupported image format');  // Обрабатываем неподдерживаемый формат
    end;
  end
  else
  begin
    raise Exception.Create('No image available in Picture');  // Обрабатываем отсутствие изображения
  end;
end;

function ExtractImageFormat(Picture: TPicture): TImageFormat;
var
  MemoryStream: TMemoryStream;
begin
  Result := ifUnknown;
  MemoryStream := TMemoryStream.Create;
  try
    if SavePictureToStream(Picture, MemoryStream) then
    begin
      MemoryStream.Position := 0;
      Result := GetImageFormatFromStream(MemoryStream);
    end;
  finally
    MemoryStream.Free;
  end;
end;

procedure GetGraphicType(Picture: TPicture);
var
  GraphicType: string;
begin
  if Assigned(Picture) and Assigned(Picture.Graphic) then
  begin
    // Проверяем тип объекта и задаем соответствующее сообщение
    if Picture.Graphic is TBitmap then
      GraphicType := 'Bitmap'
    else if Picture.Graphic is TJPEGImage then
      GraphicType := 'JPEG'
    else if Picture.Graphic is TPngImage then
      GraphicType := 'PNG'
    else if Picture.Graphic is TIcon then
      GraphicType := 'Icon'
    else if Picture.Graphic is TMetafile then
      GraphicType := 'Metafile'
    else
      GraphicType := 'Unknown format'; // Если тип не распознан

    // Выводим тип объекта
    ShowMessage('Тип графики: ' + GraphicType);
  end
  else
  begin
    ShowMessage('Picture or its graphic is not assigned.');
  end;
end;

end.