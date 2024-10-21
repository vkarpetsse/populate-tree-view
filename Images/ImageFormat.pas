unit ImageFormat;

interface

uses
  SysUtils, Classes;

type
  TImageFormat = (ifUnknown, ifPNG, ifJPEG, ifBMP, ifJFIFHeader, ifGIF, ifTIFF, ifWEBP, ifSVG, ifHEIF, ifPCX, ifRAW);

// Заголовки форматов изображений
const
  // PNG: Первые 8 байтов всегда будут: 89 50 4E 47 0D 0A 1A 0A
  PNGHeader: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);

  // JPEG: Первые 2 байта всегда: FF D8
  JPEGHeader: array[0..1] of Byte = ($FF, $D8);

  // BMP: Первые 2 байта всегда: 42 4D (соответствует символам "BM")
  BMPHeader: array[0..1] of Byte = ($42, $4D);

  // JFIF: Первые 16 байтов. Содержит идентификатор "JFIF" и дополнительные метаданные.
  JFIFHeader: array[0..10] of Byte = (  // Изменено на 20 элементов
    $FF, $D8, $FF, $E0, // SOI и APP0
    $00, $10,           // Длина APP0
    $4A, $46, $49, $46, // 'JFIF' в ASCII
    $00
  );

  // GIF: Первые 3 байта будут: 47 49 46 (соответствует "GIF")
  GIFHeader: array[0..2] of Byte = ($47, $49, $46); // "GIF"

  // TIFF: Первые 4 байта могут начинаться с II (Little Endian) или MM (Big Endian)
  TIFFHeader: array[0..3] of Byte = ($49, $49, $2A, $00); // TIFF Little Endian
  TIFFHeaderBigEndian: array[0..3] of Byte = ($4D, $4D, $2A, $00); // TIFF Big Endian

  // WEBP: Первые 4 байта будут: 52 49 46 46 (соответствует "RIFF")
  WEBPHeader: array[0..3] of Byte = ($52, $49, $46, $46); // "RIFF"

  // SVG: Обычно это XML-файл, который начинается с <?xml и содержит тег <svg>.
  // Первые 4 байта: 3C 3F 78 6D соответствуют "<?xm"
  SVGHeader: array[0..3] of Byte = ($3C, $3F, $78, $6D); // "<?xm"

  // HEIF: Первые 4 байта содержат "ftyp"
  HEIFHeader: array[0..3] of Byte = ($66, $74, $79, $70); // "ftyp"

  // PCX: Первые 2 байта: 0A 00 (также существует заголовок, который может варьироваться)
  PCXHeader: array[0..1] of Byte = ($0A, $00); // PCX

  // RAW: RAW-форматы могут иметь различные заголовки, но для примера мы используем JPEG заголовок.
  RAWHeader: array[0..1] of Byte = ($FF, $D8); // RAW, заголовок JPEG

  function GetImageFormatFromFile(const FileName: string): TImageFormat;
  function GetImageFormatFromStream(Stream: TStream): TImageFormat;

implementation

function IsJFIF(const Header: array of Byte): Boolean;
const
  JFIFSignature: array[0..4] of Byte = ($4A, $46, $49, $46, $00); // 'JFIF' + нуль-байт
begin
  // Проверка на наличие APP0 маркера (FF D8 FF E0) и сигнатуры JFIF
  Result := (Length(Header) >= 11) and
            (Header[0] = $FF) and (Header[1] = $D8) and // SOI
            (Header[2] = $FF) and (Header[3] = $E0) and // APP0
            CompareMem(@Header[6], @JFIFSignature[0], SizeOf(JFIFSignature));
end;

function GetImageFormatFromFile(const FileName: string): TImageFormat;
var
  Stream: TFileStream;
  Header: array[0..15] of Byte;
begin
  Result := ifUnknown; // По умолчанию

  // Открываем файл для чтения
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    // Читаем первые 15 байт из файла
    if Stream.Read(Header, SizeOf(Header)) = SizeOf(Header) then
    begin
      // Проверка на JFIF
      if CompareMem(@Header[0], @JFIFHeader[0], SizeOf(JFIFHeader)) then
        Exit(ifJFIFHeader);

      // Проверка на JPEG
      if CompareMem(@Header[0], @JPEGHeader[0], SizeOf(JPEGHeader)) then
        Exit(ifJPEG);

      // Проверка на PNG
      if CompareMem(@Header[0], @PNGHeader[0], SizeOf(PNGHeader)) then
        Exit(ifPNG);

      // Проверка на BMP
      if CompareMem(@Header[0], @BMPHeader[0], SizeOf(BMPHeader)) then
        Exit(ifBMP);

      // Проверка на GIF
      if CompareMem(@Header[0], @GIFHeader[0], SizeOf(GIFHeader)) then
        Exit(ifGIF);

      // Проверка на TIFF
      if CompareMem(@Header[0], @TIFFHeader[0], SizeOf(TIFFHeader)) then
        Exit(ifTIFF);

      // Проверка на WEBP
      if CompareMem(@Header[0], @WEBPHeader[0], SizeOf(WEBPHeader)) then
        Exit(ifWEBP);

      // Проверка на SVG
      if CompareMem(@Header[0], @SVGHeader[0], SizeOf(SVGHeader)) then
        Exit(ifSVG);

      // Проверка на HEIF
      if CompareMem(@Header[0], @HEIFHeader[0], SizeOf(HEIFHeader)) then
        Exit(ifHEIF);

      // Проверка на PCX
      if CompareMem(@Header[0], @PCXHeader[0], SizeOf(PCXHeader)) then
        Exit(ifPCX);

      // Проверка на RAW
      if CompareMem(@Header[0], @RAWHeader[0], SizeOf(RAWHeader)) then
        Exit(ifRAW);
    end;
  finally
    Stream.Free; // Освобождаем ресурс
  end;
end;

function GetImageFormatFromStream(Stream: TStream): TImageFormat;
var
  Header: array[0..15] of Byte;
begin
  Result := ifUnknown; // По умолчанию

  // Читаем первые 15 байт из потока
  if Stream.Read(Header, SizeOf(Header)) = SizeOf(Header) then
  begin
    if CompareMem(@Header[0], @JFIFHeader[0], SizeOf(JFIFHeader)) then
      Exit(ifJFIFHeader);

    // Проверка на JPEG
    if CompareMem(@Header[0], @JPEGHeader[0], SizeOf(JPEGHeader)) then
    begin
      // Проверка на JFIF
      if IsJFIF(Header) then
        Exit(ifJFIFHeader)
      else
        Exit(ifJPEG);
    end;

    // Проверка на PNG
    if CompareMem(@Header[0], @PNGHeader[0], SizeOf(PNGHeader)) then
      Exit(ifPNG);

    // Проверка на BMP
    if CompareMem(@Header[0], @BMPHeader[0], SizeOf(BMPHeader)) then
      Exit(ifBMP);

    // Проверка на GIF
    if CompareMem(@Header[0], @GIFHeader[0], SizeOf(GIFHeader)) then
      Exit(ifGIF);

    // Проверка на TIFF
    if CompareMem(@Header[0], @TIFFHeader[0], SizeOf(TIFFHeader)) then
      Exit(ifTIFF);

    // Проверка на WEBP
    if CompareMem(@Header[0], @WEBPHeader[0], SizeOf(WEBPHeader)) then
      Exit(ifWEBP);

    // Проверка на SVG
    if CompareMem(@Header[0], @SVGHeader[0], SizeOf(SVGHeader)) then
      Exit(ifSVG);

    // Проверка на HEIF
    if CompareMem(@Header[0], @HEIFHeader[0], SizeOf(HEIFHeader)) then
      Exit(ifHEIF);

    // Проверка на PCX
    if CompareMem(@Header[0], @PCXHeader[0], SizeOf(PCXHeader)) then
      Exit(ifPCX);

    // Проверка на RAW
    if CompareMem(@Header[0], @RAWHeader[0], SizeOf(RAWHeader)) then
      Exit(ifRAW);
  end;
end;

function GetImageFormatFromBlob(const Blob: TStream): TImageFormat;
begin
  Result := GetImageFormatFromStream(Blob);
end;

end.