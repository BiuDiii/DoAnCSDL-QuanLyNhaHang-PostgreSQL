CREATE DATABASE QuanLyNhaHang;
GO
USE QuanLyNhaHang;
GO

/* ==========================================================================
   PHAN 1: NGUYEN BAN FILE
   ========================================================================== */

/* Xoa bang theo thu tu khoa ngoai de co the chay lai bat ky luc nao */
DROP TABLE IF EXISTS CHITIETKIEMKE, KIEMKE, CHITIETPHIEUXUAT, PHIEUXUAT, NGUYENLIEU, 
                     DATBAN, CHITIETHOADON, HOADON, PHANCA, NHANVIEN, BANAN, KHUVUC, MONAN, LOAIMON;
GO

/* 1.1 TAO CAC BANG CO BAN */
CREATE TABLE LOAIMON (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE MONAN (
    MaMon INT PRIMARY KEY,
    TenMon NVARCHAR(100) NOT NULL UNIQUE,
    MaLoai INT NOT NULL,
    DonGia DECIMAL(12,0) NOT NULL CHECK (DonGia >= 0),
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Còn món'
        CHECK (TrangThai IN (N'Còn món', N'Hết món', N'Ngừng bán')),
    FOREIGN KEY (MaLoai) REFERENCES LOAIMON(MaLoai)
);

CREATE TABLE KHUVUC (
    MaKhuVuc INT PRIMARY KEY,
    TenKhuVuc NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE BANAN (
    MaBan INT PRIMARY KEY,
    TenBan NVARCHAR(50) NOT NULL UNIQUE,
    MaKhuVuc INT NOT NULL,
    SoCho INT NOT NULL CHECK (SoCho > 0),
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Trống'
        CHECK (TrangThai IN (N'Trống', N'Đang dùng', N'Đã đặt')),
    FOREIGN KEY (MaKhuVuc) REFERENCES KHUVUC(MaKhuVuc)
);

CREATE TABLE NHANVIEN (
    MaNV INT PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    NgaySinh DATE CHECK (NgaySinh < GETDATE() AND YEAR(GETDATE()) - YEAR(NgaySinh) >= 16),
    GioiTinh NVARCHAR(10) NOT NULL CHECK (GioiTinh IN (N'Nam', N'Nữ', N'Khác')),
    DienThoai VARCHAR(10) NOT NULL UNIQUE
        CHECK (DienThoai LIKE '0%' AND LEN(DienThoai) = 10 AND DienThoai NOT LIKE '%[^0-9]%'),
    Email VARCHAR(100) CHECK (Email LIKE '%@%'),
    ChucVu NVARCHAR(50) NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Đang làm'
        CHECK (TrangThai IN (N'Đang làm', N'Nghỉ việc'))
);

CREATE TABLE PHANCA (
    MaPhanCa INT IDENTITY(1,1) PRIMARY KEY,
    MaNV INT NOT NULL,
    CaLam NVARCHAR(100) NOT NULL,
    NgayLam DATE NOT NULL,
    MaKhuVuc INT NOT NULL,
    CONSTRAINT FK_PHANCA_NHANVIEN FOREIGN KEY (MaNV) REFERENCES NHANVIEN(MaNV),
    CONSTRAINT FK_PHANCA_KHUVUC FOREIGN KEY (MaKhuVuc) REFERENCES KHUVUC(MaKhuVuc)
);

CREATE TABLE HOADON (
    MaHD INT IDENTITY(1,1) PRIMARY KEY,
    MaBan INT NOT NULL REFERENCES BANAN(MaBan),
    MaNV INT NOT NULL REFERENCES NHANVIEN(MaNV),
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(12,0) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    GiamGia DECIMAL(12,0) NOT NULL DEFAULT 0 CHECK (GiamGia >= 0),
    ThanhTien AS (TongTien - GiamGia),
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Chưa thanh toán'
        CHECK (TrangThai IN (N'Chưa thanh toán', N'Đã thanh toán', N'Đã hủy')),
    CHECK (GiamGia <= TongTien)
);

CREATE TABLE CHITIETHOADON (
    MaHD INT NOT NULL REFERENCES HOADON(MaHD),
    MaMon INT NOT NULL REFERENCES MONAN(MaMon),
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(12,0) NOT NULL CHECK (DonGia >= 0),
    ThanhTien AS (SoLuong * DonGia),
    PRIMARY KEY (MaHD, MaMon)
);
GO

/* 1.2 INDEX */
CREATE UNIQUE INDEX UX_NHANVIEN_Email ON NHANVIEN(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_HOADON_ChuaTT ON HOADON(MaBan) WHERE TrangThai = N'Chưa thanh toán';
GO

/* 1.3 TRIGGER */
CREATE TRIGGER trg_TinhTongTien ON CHITIETHOADON
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE HOADON
    SET TongTien = (SELECT ISNULL(SUM(ThanhTien), 0)
                    FROM CHITIETHOADON
                    WHERE CHITIETHOADON.MaHD = HOADON.MaHD)
    WHERE MaHD IN (SELECT MaHD FROM inserted)
       OR MaHD IN (SELECT MaHD FROM deleted);
END;
GO

CREATE TRIGGER trg_DoiTrangThaiBan ON HOADON
AFTER INSERT, UPDATE
AS
BEGIN
    IF UPDATE(TrangThai)
    BEGIN
        UPDATE BANAN SET TrangThai = N'Đang dùng'
        WHERE MaBan IN (SELECT MaBan FROM inserted WHERE TrangThai = N'Chưa thanh toán');

        UPDATE BANAN SET TrangThai = N'Trống'
        WHERE MaBan IN (SELECT MaBan FROM inserted WHERE TrangThai IN (N'Đã thanh toán', N'Đã hủy'));
    END
END;
GO

/* 1.4 DU LIEU MAU BAN DAU */
INSERT INTO LOAIMON VALUES
(1,N'Món chính'),(2,N'Món khai vị'),(3,N'Đồ uống'),(4,N'Món ăn vặt'),(5,N'Tráng miệng');

INSERT INTO MONAN VALUES
(101,N'Cơm chiên dương châu',1,45000,N'Còn món'),
(102,N'Phở bò',1,50000,N'Còn món'),
(103,N'Gỏi cuốn',2,30000,N'Còn món'),
(104,N'Trà đào',3,25000,N'Còn món'),
(105,N'Khoai tây chiên',4,35000,N'Còn món'),
(106,N'Rau câu',5,15000,N'Còn món');

INSERT INTO KHUVUC VALUES
(1,N'Tầng 1'),(2,N'Tầng 2'),(3,N'Ngoài trời'),(4,N'Phòng VIP'),(5,N'Sân vườn');

INSERT INTO BANAN VALUES
(1,N'Bàn 01',1,4,N'Trống'),
(2,N'Bàn 02',1,4,N'Trống'),
(3,N'Bàn 03',2,6,N'Trống'),
(4,N'Bàn VIP 01',4,8,N'Trống'),
(5,N'Bàn sân vườn 01',5,4,N'Trống'),
(18,N'Bàn 18',3,4,N'Đã đặt'),
(22,N'Bàn 22',4,6,N'Đã đặt');

INSERT INTO NHANVIEN VALUES
(1,N'Nguyễn Văn An','2000-03-15',N'Nam','0901234567','an@gmail.com',N'Quản lý',N'Đang làm'),
(2,N'Trần Thị Bình','2002-07-20',N'Nữ','0912345678','binh@gmail.com',N'Phục vụ',N'Đang làm'),
(3,N'Lê Văn Cường','2001-11-05',N'Nam','0923456789','cuong@gmail.com',N'Đầu bếp',N'Đang làm'),
(4,N'Phạm Thị Dung','2003-01-12',N'Nữ','0934567890','dung@gmail.com',N'Thu ngân',N'Đang làm'),
(5,N'Hoàng Minh Đức','1999-09-25',N'Nam','0945678901','duc@gmail.com',N'Phục vụ',N'Đang làm');

INSERT INTO PHANCA (MaNV, CaLam, NgayLam, MaKhuVuc) VALUES
(1, N'Ca sáng (07:00 - 11:00)', CAST(GETDATE() AS DATE), 1),
(2, N'Ca chiều (11:00 - 16:00)', CAST(GETDATE() AS DATE), 2),
(3, N'Ca tối (16:00 - 22:00)',   CAST(GETDATE() AS DATE), 3);
GO

/* 1.5 BO SUNG COT GIO VAO & GIO THANH TOAN VAO HOADON */
ALTER TABLE HOADON ADD GioVao DATETIME DEFAULT GETDATE();
ALTER TABLE HOADON ADD GioThanhToan DATETIME NULL;
GO

UPDATE HOADON SET GioVao = NgayTao WHERE GioVao IS NULL;
UPDATE HOADON SET GioThanhToan = DATEADD(MINUTE, 45, NgayTao) WHERE TrangThai = N'Đã thanh toán' AND GioThanhToan IS NULL;
GO


/* ==========================================================================
   PHAN 2: CAC PHAN BO SUNG TIEP THEO CUA NHOM
   ========================================================================== */

/* 2.1 BO SUNG COT CHO BANG KHUVUC */
ALTER TABLE KHUVUC ADD
    ViTri NVARCHAR(100) NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Hoạt động'
        CHECK (TrangThai IN (N'Hoạt động', N'Bảo trì')),
    GhiChu NVARCHAR(255) NULL;
GO

UPDATE KHUVUC SET ViTri = N'Tầng 1'   WHERE MaKhuVuc = 1;
UPDATE KHUVUC SET ViTri = N'Tầng 2'   WHERE MaKhuVuc = 2;
UPDATE KHUVUC SET ViTri = N'Sân trước' WHERE MaKhuVuc = 3;
UPDATE KHUVUC SET ViTri = N'Tầng 3'   WHERE MaKhuVuc = 4;
UPDATE KHUVUC SET ViTri = N'Sân sau', TrangThai = N'Bảo trì' WHERE MaKhuVuc = 5;
GO

/* 2.2 TAO BANG DATBAN VA DU LIEU MAU */
CREATE TABLE DATBAN (
    MaDat VARCHAR(10) PRIMARY KEY,
    TenKhach NVARCHAR(100) NOT NULL,
    SDT VARCHAR(10) NOT NULL
        CHECK (SDT LIKE '0%' AND LEN(SDT) = 10 AND SDT NOT LIKE '%[^0-9]%'),
    MaBan INT NOT NULL REFERENCES BANAN(MaBan),
    GioHen VARCHAR(5) NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Đã đặt'
        CHECK (TrangThai IN (N'Đã đặt', N'Đã nhận bàn', N'Đã hủy'))
);

CREATE UNIQUE INDEX UX_DATBAN_Ban_Gio ON DATBAN(MaBan, GioHen)
WHERE TrangThai <> N'Đã hủy';
GO

INSERT INTO DATBAN VALUES
('DB01', N'Trần Minh Hoàng', '0901234567', 18, '18:30', N'Đã đặt'),
('DB02', N'Lê Thu Hà',       '0912345678', 3,  '19:00', N'Đã nhận bàn'),
('DB03', N'Phạm Quốc Khánh', '0987654321', 22, '20:00', N'Đã đặt');
GO

/* 2.3 BO SUNG THONG TIN LOAIMON */
ALTER TABLE LOAIMON ADD
    DonViTinh NVARCHAR(30) NULL,
    TrangThai NVARCHAR(20) NOT NULL
        CONSTRAINT DF_LOAIMON_TrangThai DEFAULT N'Đang kinh doanh',
    CONSTRAINT CK_LOAIMON_TrangThai CHECK (TrangThai IN (N'Đang kinh doanh', N'Ngừng kinh doanh'));
GO

UPDATE LOAIMON SET DonViTinh = CASE MaLoai
    WHEN 1 THEN N'Phần / Tô'
    WHEN 2 THEN N'Đĩa'
    WHEN 3 THEN N'Ly / Lon'
    WHEN 4 THEN N'Đĩa'
    WHEN 5 THEN N'Phần'
END;
GO

/* 2.4 BO SUNG SO LUONG TON DU KIEN CHO MONAN */
ALTER TABLE MONAN ADD SoLuongTonDuKien INT NULL CHECK (SoLuongTonDuKien >= 0);
GO

UPDATE MONAN SET 
    SoLuongTonDuKien = CASE MaMon
        WHEN 101 THEN 20
        WHEN 102 THEN 15
        WHEN 103 THEN 12
        WHEN 104 THEN 10
        WHEN 105 THEN 0
        WHEN 106 THEN 8
    END,
    TrangThai = CASE MaMon
        WHEN 105 THEN N'Hết món'
        ELSE N'Còn món'
    END
WHERE MaMon IN (101, 102, 103, 104, 105, 106);
GO

--SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
--Modul 1 2

USE QuanLyNhaHang;
GO

-- 1. BANG NGUYEN LIEU
CREATE TABLE NGUYENLIEU (
    MaNL INT PRIMARY KEY,
    TenNL NVARCHAR(100) NOT NULL UNIQUE,
    LoaiNL NVARCHAR(50) NOT NULL,
    DonViTinh NVARCHAR(30) NOT NULL,
    SoLuongTon DECIMAL(12,2) NOT NULL DEFAULT 0
        CHECK (SoLuongTon >= 0),
    MucTonToiThieu DECIMAL(12,2) NOT NULL DEFAULT 5
        CHECK (MucTonToiThieu >= 0),
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Đang sử dụng'
        CHECK (TrangThai IN (N'Đang sử dụng', N'Ngừng sử dụng'))
);
GO

-- 2. BANG NHA CUNG CAP
CREATE TABLE NHACUNGCAP (
    MaNCC INT PRIMARY KEY,
    TenNCC NVARCHAR(100) NOT NULL,
    SDT VARCHAR(10) NOT NULL UNIQUE,
    DiaChi NVARCHAR(200),
    Email VARCHAR(100),
    GhiChu NVARCHAR(255)
);
GO

-- 3. BANG PHIEU NHAP
CREATE TABLE PHIEUNHAP (
    MaPN INT IDENTITY(1,1) PRIMARY KEY,
    MaNCC INT NOT NULL,
    NgayNhap DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(18,2) NOT NULL DEFAULT 0
        CHECK (TongTien >= 0),
    GhiChu NVARCHAR(255),
    FOREIGN KEY (MaNCC) REFERENCES NHACUNGCAP(MaNCC)
);
GO

-- 4. BANG CHI TIET PHIEU NHAP
CREATE TABLE CHITIETPHIEUNHAP (
    MaPN INT NOT NULL,
    MaNL INT NOT NULL,
    SoLuong DECIMAL(12,2) NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(18,2) NOT NULL CHECK (DonGia >= 0),
    ThanhTien AS (SoLuong * DonGia),
    PRIMARY KEY (MaPN, MaNL),
    FOREIGN KEY (MaPN) REFERENCES PHIEUNHAP(MaPN),
    FOREIGN KEY (MaNL) REFERENCES NGUYENLIEU(MaNL)
);
GO

-- 5. TRIGGER TU DONG TINH TONG TIEN PHIEU NHAP
CREATE TRIGGER trg_TinhTongTienNhap
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PN
    SET TongTien = ISNULL((
        SELECT SUM(CT.ThanhTien)
        FROM CHITIETPHIEUNHAP CT
        WHERE CT.MaPN = PN.MaPN
    ), 0)
    FROM PHIEUNHAP PN
    WHERE PN.MaPN IN (SELECT MaPN FROM inserted)
       OR PN.MaPN IN (SELECT MaPN FROM deleted);
END;
GO

-- 6. TRIGGER CAP NHAT SO LUONG TON
CREATE TRIGGER trg_CapNhatTonKho
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH BienDong AS (
        SELECT MaNL, SUM(SoLuong) AS SoLuong
        FROM inserted
        GROUP BY MaNL

        UNION ALL

        SELECT MaNL, -SUM(SoLuong) AS SoLuong
        FROM deleted
        GROUP BY MaNL
    ),
    TongBienDong AS (
        SELECT MaNL, SUM(SoLuong) AS SoLuong
        FROM BienDong
        GROUP BY MaNL
    )
    UPDATE NL
    SET SoLuongTon = NL.SoLuongTon + BD.SoLuong
    FROM NGUYENLIEU NL
    JOIN TongBienDong BD ON NL.MaNL = BD.MaNL;
END;
GO

INSERT INTO NGUYENLIEU
(MaNL, TenNL, LoaiNL, DonViTinh, SoLuongTon, MucTonToiThieu)
VALUES
(1, N'Gạo tẻ', N'Ngũ cốc', N'Kg', 20, 5),
(2, N'Thịt bò', N'Thịt', N'Kg', 10, 3),
(3, N'Rau cải', N'Rau củ', N'Kg', 8, 5),
(4, N'Dầu ăn', N'Gia vị', N'Chai', 3, 5),
(5, N'Nước mắm', N'Gia vị', N'Chai', 12, 4);

INSERT INTO NHACUNGCAP
(MaNCC, TenNCC, SDT, DiaChi, Email)
VALUES
(1, N'Công ty thực phẩm An Phát',
 '0901234567', N'Hà Nội', 'anphat@gmail.com'),
(2, N'Nhà cung cấp Minh Đức',
 '0912345678', N'Hà Đông, Hà Nội', 'minhduc@gmail.com');

-- Tao phieu nhap mau
INSERT INTO PHIEUNHAP (MaNCC, GhiChu)
VALUES (1, N'Nhập nguyên liệu lần đầu');

-- Nhap chi tiet
INSERT INTO CHITIETPHIEUNHAP
(MaPN, MaNL, SoLuong, DonGia)
VALUES
(1, 1, 20, 15000),
(1, 2, 10, 200000),
(1, 3, 15, 12000);
GO

-- Kiem tra ket qua
SELECT * FROM NGUYENLIEU;
SELECT * FROM NHACUNGCAP;
SELECT * FROM PHIEUNHAP;
SELECT * FROM CHITIETPHIEUNHAP;
GO



/* 2.5 BO SUNG QUAN LY XUAT KHO, TON KHO & KIEM KE (THANH VIEN 2 - MODULE 3 & 4) */

-- Bảng danh mục nguyên liệu
CREATE TABLE NGUYENLIEU (
    MaNL INT PRIMARY KEY,
    TenNL NVARCHAR(100) NOT NULL UNIQUE,
    DonViTinh NVARCHAR(20) NOT NULL,
    SoLuongTon DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (SoLuongTon >= 0),
    MucTonToiThieu DECIMAL(10,2) NOT NULL DEFAULT 5 CHECK (MucTonToiThieu >= 0),
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'Đủ hàng'
        CHECK (TrangThai IN (N'Đủ hàng', N'Sắp hết', N'Hết hàng'))
);

-- Module 3: Quản lý xuất kho
CREATE TABLE PHIEUXUAT (
    MaPX INT IDENTITY(1,1) PRIMARY KEY,
    NgayXuat DATETIME NOT NULL DEFAULT GETDATE(),
    MaNV INT NOT NULL REFERENCES NHANVIEN(MaNV),
    MucDichXuat NVARCHAR(100) NOT NULL 
        CHECK (MucDichXuat IN (N'Chế biến món ăn', N'Hủy hàng hỏng/hết hạn', N'Xuất trả nhà cung cấp', N'Khác')),
    GhiChu NVARCHAR(255) NULL
);

CREATE TABLE CHITIETPHIEUXUAT (
    MaPX INT NOT NULL REFERENCES PHIEUXUAT(MaPX) ON DELETE CASCADE,
    MaNL INT NOT NULL REFERENCES NGUYENLIEU(MaNL),
    SoLuongXuat DECIMAL(10,2) NOT NULL CHECK (SoLuongXuat > 0),
    PRIMARY KEY (MaPX, MaNL)
);

-- Module 4: Quản lý tồn kho và kiểm kê
CREATE TABLE KIEMKE (
    MaKK INT IDENTITY(1,1) PRIMARY KEY,
    NgayKiemKe DATETIME NOT NULL DEFAULT GETDATE(),
    MaNV INT NOT NULL REFERENCES NHANVIEN(MaNV),
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'Đã chốt số liệu'
        CHECK (TrangThai IN (N'Đang kiểm kê', N'Đã chốt số liệu')),
    GhiChu NVARCHAR(255) NULL
);

CREATE TABLE CHITIETKIEMKE (
    MaKK INT NOT NULL REFERENCES KIEMKE(MaKK) ON DELETE CASCADE,
    MaNL INT NOT NULL REFERENCES NGUYENLIEU(MaNL),
    SoLuongHeThong DECIMAL(10,2) NOT NULL CHECK (SoLuongHeThong >= 0),
    SoLuongThucTe DECIMAL(10,2) NOT NULL CHECK (SoLuongThucTe >= 0),
    ChenhLech AS (SoLuongThucTe - SoLuongHeThong),
    LyDoChenhLech NVARCHAR(255) NULL,
    PRIMARY KEY (MaKK, MaNL)
);
GO

-- Trigger: Kiểm tra tồn kho trước khi xuất, tự động trừ tồn và cập nhật cảnh báo
CREATE TRIGGER trg_KiemTraVaTruTonKhiXuat ON CHITIETPHIEUXUAT
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN NGUYENLIEU nl ON i.MaNL = nl.MaNL
        WHERE nl.SoLuongTon < i.SoLuongXuat
    )
    BEGIN
        RAISERROR (N'Lỗi: Số lượng nguyên liệu trong kho không đủ để xuất!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE nl
    SET nl.SoLuongTon = nl.SoLuongTon - i.SoLuongXuat
    FROM NGUYENLIEU nl
    JOIN inserted i ON nl.MaNL = i.MaNL;

    UPDATE NGUYENLIEU
    SET TrangThai = CASE 
        WHEN SoLuongTon = 0 THEN N'Hết hàng'
        WHEN SoLuongTon <= MucTonToiThieu THEN N'Sắp hết'
        ELSE N'Đủ hàng'
    END
    WHERE MaNL IN (SELECT MaNL FROM inserted);
END;
GO

-- Trigger: Cập nhật lại tồn kho thực tế sau khi chốt kiểm kê
CREATE TRIGGER trg_CapNhatTonSauKiemKe ON CHITIETKIEMKE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE nl
    SET nl.SoLuongTon = i.SoLuongThucTe,
        nl.TrangThai = CASE 
            WHEN i.SoLuongThucTe = 0 THEN N'Hết hàng'
            WHEN i.SoLuongThucTe <= nl.MucTonToiThieu THEN N'Sắp hết'
            ELSE N'Đủ hàng'
        END
    FROM NGUYENLIEU nl
    JOIN inserted i ON nl.MaNL = i.MaNL
    JOIN KIEMKE kk ON i.MaKK = kk.MaKK
    WHERE kk.TrangThai = N'Đã chốt số liệu';
END;
GO

-- Dữ liệu mẫu cho Kho & Kiểm kê
INSERT INTO NGUYENLIEU (MaNL, TenNL, DonViTinh, SoLuongTon, MucTonToiThieu) VALUES
(1, N'Gạo tám thơm', N'Kg', 50.00, 10.00),
(2, N'Thịt bò thăn', N'Kg', 15.00, 5.00),
(3, N'Bánh phở tươi', N'Kg', 20.00, 5.00),
(4, N'Trà đen túi lọc', N'Hộp', 12.00, 3.00),
(5, N'Khoai tây đông lạnh', N'Kg', 4.00, 5.00);
GO

UPDATE NGUYENLIEU SET TrangThai = N'Sắp hết' WHERE SoLuongTon <= MucTonToiThieu;
GO

INSERT INTO PHIEUXUAT (MaNV, MucDichXuat, GhiChu) VALUES
(3, N'Chế biến món ăn', N'Xuất nguyên liệu chuẩn bị ca tối'),
(3, N'Hủy hàng hỏng/hết hạn', N'Khoai tây bị ẩm mốc');

INSERT INTO CHITIETPHIEUXUAT (MaPX, MaNL, SoLuongXuat) VALUES
(1, 1, 5.00),
(1, 2, 3.50),
(2, 5, 2.00);
GO

INSERT INTO KIEMKE (MaNV, TrangThai, GhiChu) VALUES
(1, N'Đã chốt số liệu', N'Kiểm kê định kỳ cuối ngày');

INSERT INTO CHITIETKIEMKE (MaKK, MaNL, SoLuongHeThong, SoLuongThucTe, LyDoChenhLech) VALUES
(1, 1, 45.00, 45.00, N'Khớp số liệu'),
(1, 2, 11.50, 11.20, N'Hao hụt tự nhiên trong quá trình sơ chế'),
(1, 4, 12.00, 12.00, N'Khớp số liệu');
GO


/* ==========================================================================
   PHAN 3: KIEM TRA DU LIEU TOAN BO HE THONG
   ========================================================================== */
SELECT * FROM LOAIMON;
SELECT * FROM MONAN;
SELECT * FROM KHUVUC;
SELECT * FROM BANAN;
SELECT * FROM NHANVIEN;
SELECT * FROM PHANCA;
SELECT * FROM DATBAN;
SELECT * FROM HOADON;
SELECT * FROM CHITIETHOADON;
SELECT * FROM NGUYENLIEU;
SELECT * FROM PHIEUXUAT;
SELECT * FROM CHITIETPHIEUXUAT;
SELECT * FROM KIEMKE;
SELECT * FROM CHITIETKIEMKE;
GO