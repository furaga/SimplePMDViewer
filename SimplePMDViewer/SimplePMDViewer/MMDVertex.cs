using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;
using System.Runtime.InteropServices;

namespace SimplePMDViewer
{

    [StructLayout(LayoutKind.Sequential)]
    struct VertexPositionNormal : IVertexType
    {
        public Vector3 Position;
        public Vector3 Normal;
        // メンバPosition, Normalがそれぞれどのようにメモリにマッピングされ、どのような用途で使われるかを指定
        public readonly static VertexDeclaration vertexDeclaration =
            new VertexDeclaration(
                new VertexElement(0, VertexElementFormat.Vector3, VertexElementUsage.Position, 0),
                new VertexElement(3 * sizeof(float), VertexElementFormat.Vector3, VertexElementUsage.Normal, 0)
            );
        public VertexDeclaration VertexDeclaration { get { return vertexDeclaration; } }
    }
    // struct VertexPositionNormalTexture はXNAのライブラリとしてすでに定義されている
}
