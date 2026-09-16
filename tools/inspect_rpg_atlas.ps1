param([Parameter(Mandatory=$true)][string]$Source, [Parameter(Mandatory=$true)][string]$Output)
Add-Type -AssemblyName System.Drawing
if (-not ('NeonRequiem.AtlasInspection' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
namespace NeonRequiem {
public class Island {
    public int x,y,width,height,pixels;
    public double centerX,centerY;
}
public static class AtlasInspection {
    public static List<Island> Read(byte[] rgba,int w,int h,int stride) {
            var used=new bool[w*h];
            var queue=new int[w*h];
            var islands=new List<Island>();
            for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
                int first=y*w+x;
                if(used[first]||rgba[y*stride+x*4+3]<64) continue;
                int read=0,write=1;
                queue[0]=first;used[first]=true;
                int minX=x,maxX=x,minY=y,maxY=y;
                long sumX=0,sumY=0;
                while(read<write) {
                    int p=queue[read++],px=p%w,py=p/w;
                    minX=Math.Min(minX,px);maxX=Math.Max(maxX,px);
                    minY=Math.Min(minY,py);maxY=Math.Max(maxY,py);
                    sumX+=px;sumY+=py;
                    for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
                        int nx=px+dx,ny=py+dy;
                        if(nx<0||ny<0||nx>=w||ny>=h) continue;
                        int np=ny*w+nx;
                        if(used[np]||rgba[ny*stride+nx*4+3]<64) continue;
                        used[np]=true;queue[write++]=np;
                    }
                }
                if(write>=400) islands.Add(new Island {x=minX,y=minY,width=maxX-minX+1,height=maxY-minY+1,pixels=write,centerX=(double)sumX/write,centerY=(double)sumY/write});
            }
            return islands;
    }
}}
'@
}
$bitmap=[System.Drawing.Bitmap]::new((Resolve-Path -LiteralPath $Source).Path)
$sheetWidth=$bitmap.Width
$sheetHeight=$bitmap.Height
$data=$bitmap.LockBits([System.Drawing.Rectangle]::new(0,0,$sheetWidth,$sheetHeight),[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride=$data.Stride
$pixels=[byte[]]::new([Math]::Abs($stride)*$sheetHeight)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
$bitmap.UnlockBits($data)
$bitmap.Dispose()
$islands=[NeonRequiem.AtlasInspection]::Read($pixels,$sheetWidth,$sheetHeight,$stride)
$frames=@()
for($row=0;$row -lt 4;$row++) {
    $rowIslands=@($islands | Where-Object { [Math]::Floor($_.centerY/($sheetHeight/4)) -eq $row } | Sort-Object centerX)
    if($rowIslands.Count -ne 8) { throw "Expected 8 complete sprites in row $row; found $($rowIslands.Count). Inspect the sheet before importing." }
    # Register all poses against the idle boot baseline, correcting row spacing
    # in the source without changing any pixels or following the lowered weapon.
    $footBaseline=$rowIslands[0].y+$rowIslands[0].height
    for($column=0;$column -lt 8;$column++) {
        $island=$rowIslands[$column]
        $x=[Math]::Max(0,$island.x-2)
        $y=[Math]::Max(0,$island.y-2)
        $right=[Math]::Min($sheetWidth,$island.x+$island.width+2)
        $bottom=[Math]::Min($sheetHeight,$island.y+$island.height+2)
        $frames+=@{row=$row;column=$column;region=@($x,$y,($right-$x),($bottom-$y));anchor=@((($column+0.5)*$sheetWidth/8),$footBaseline);opaque_pixels=$island.pixels}
    }
}
@{width=$sheetWidth;height=$sheetHeight;columns=8;rows=4;frames=$frames} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Output -Encoding utf8
Write-Output "Validated 32 complete sprite silhouettes; saved crop/anchor metadata to $Output"
