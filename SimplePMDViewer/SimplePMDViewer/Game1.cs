using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.GamerServices;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging; 

namespace SimplePMDViewer
{
    public class Game1 : Microsoft.Xna.Framework.Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        MMDModel.MMDModel model;

        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";

            graphics.PreferredBackBufferWidth = 1040;
            graphics.PreferredBackBufferHeight = 1040;
        }

        protected override void Initialize()
        {
            base.Initialize();
        }

        byte[] buf;
        Texture2D texture;

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);
            model = new MMDModel.MMDModel(@"./Content/Lat���~�NVer2.3/Lat���~�NVer2.3_Sailor�ĕ�.pmd", 1);
            /*
            var filename = @"Content\BLAZER.bmp";
            int stride = 4; // i�s�N�Z���ӂ�̐F����\���f�[�^�̐��iRGBA�Ȃ̂�4�j  
            Bitmap image = (Bitmap)Image.FromFile(filename, true);
            byte[] pixel_data = new byte[image.Width * image.Height * stride];

            // �摜�����b�N����̈�  
            System.Drawing.Rectangle lock_rect = new System.Drawing.Rectangle { X = 0, Y = 0, Width = image.Width, Height = image.Height };

            // ���b�N����  
            // Rectangle rect ���b�N�̈�  
            // ImageLockMode flags ���b�N���@ ����͓ǂݎ�邾���Ȃ̂�ReadOnly���w�肷��  
            // PixelFormat format �摜�̃f�[�^�`�� RGBA�f�[�^���ق����̂�PixelFormat.Format32bppPArgb���w�肷��  
            BitmapData bitmap_data = image.LockBits(
            lock_rect,
            ImageLockMode.ReadOnly,
            PixelFormat.Format32bppPArgb);

            buf = new byte[4 * image.Height * image.Width];

            // �F���擾  
            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    int pixel_target = x * stride + bitmap_data.Stride * y;
                    int array_index = (y * image.Width + x) * stride;

                    // ���b�N�����|�C���^����F�����擾�iBGRA�̏��ԂŊi�[����Ă�j  
                    for (int i = 0; i < stride; i++)
                        buf[array_index + i] =
                            System.Runtime.InteropServices.Marshal.ReadByte(
                            bitmap_data.Scan0,
                            pixel_target + stride - ((1 + i) % stride) - 1);
                }
            }

            // ���b�N������A�����b�N��Y�ꂸ�ɁI  
            image.UnlockBits(bitmap_data);

            texture = new Texture2D(
                GraphicsDevice,
                image.Width,
                image.Height,
                false,
                SurfaceFormat.Color);

            // �F�f�[�^�z���ݒ�  
            texture.SetData<byte>(buf);
            */
        }

        protected override void Update(GameTime gameTime)
        {
            if (Keyboard.GetState().IsKeyDown(Keys.Escape)) this.Exit();


            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Microsoft.Xna.Framework.Color.Black);
            base.Draw(gameTime);
        }
    }
}
