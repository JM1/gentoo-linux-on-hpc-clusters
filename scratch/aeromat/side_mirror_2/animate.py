#!/usr/bin/env pvpython --force-offscreen-rendering

# NOTE: Option '--force-offscreen-rendering' is required to render images at resolutions higher than display resolution.

# vim:set tabstop=8 shiftwidth=4 expandtab:
# kate: syntax python; space-indent on; indent-width 4;

# Copyright (c) 2019 Jakob Meng, <jakobmeng@web.de>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


from paraview.simple import *
from math import fabs
import os
import argparse
import logging

screen_width = 2000
screen_height = 1000
print_width = 4000
print_height = 2000

prefix = 'car'

tags = [
        "pca_0",
        "pca_1",
        "pca_2",
        "pca_3",
        "pca_4",
        "pca_5-last",
        "pca_centered_normalized_all",
        "pca_centered_normalized_0-last",
        "pca_centered_normalized_none",
        "pca_centered_normalized_keep-centered_0",
        "pca_centered_normalized_keep-centered_1",
        "pca_centered_normalized_keep-centered_2",
        "pca_centered_normalized_keep-centered_3",
        "pca_centered_normalized_keep-centered_4-last",
        "pca_centered_normalized_keep-centered_0-last",
        "pca_centered_normalized_0-2"
    ]

velocity_coordinates = [ 'Magnitude', 'X', 'Y', 'Z' ]

frame_window = None

class Bounds(object):
    def __init__(self, bounds):
        # (x_min,x_max,y_min,y_max,z_min,z_max) = bounds
        self.x0 = bounds[0]
        self.x1 = bounds[1]
        self.y0 = bounds[2]
        self.y1 = bounds[3]
        self.z0 = bounds[4]
        self.z1 = bounds[5]
        
        self.dx = fabs(self.x1 - self.x0)
        self.dy = fabs(self.y1 - self.y0)
        self.dz = fabs(self.z1 - self.z0)
        
        self.cx = (self.x0 + self.x1)/2.
        self.cy = (self.y0 + self.y1)/2.
        self.cz = (self.z0 + self.z1)/2.

    def __str__(self):
        return '<x0={},x1={},y0={},y1={},z0={},z1={},dx={},dy={},dz={},cx={},cy={},cz={}>'.format(
            self.x0,self.x1,
            self.y0,self.y1,
            self.z0,self.z1,
            self.dx,self.dy,self.dz,
            self.cx,self.cy,self.cz)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', action='count',default=0)
    parser.add_argument('--prefix', default=prefix)
    parser.add_argument('--tags', nargs='*', default=tags)
    parser.add_argument('--velocity-coordinates', nargs='*', default=velocity_coordinates)
    parser.add_argument('--frame-window', nargs=2, default=frame_window)
    parser.add_argument('--reverse-connect', action='store_true')
    args = parser.parse_args()
    
    if args.verbose == 0:
        log_level = logging.WARNING
    elif args.verbose == 1:
        log_level = logging.INFO
    elif args.verbose >= 2:
        log_level = logging.DEBUG
    
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s', level=log_level)
    
    if args.frame_window:
        frame_window = [ int(args.frame_window[0]), int(args.frame_window[1]) ]
    
    if args.prefix:
        prefix = args.prefix
    
    if args.tags:
        tags = args.tags
    
    if args.velocity_coordinates:
        velocity_coordinates = args.velocity_coordinates
        
    reverse_connect = args.reverse_connect
    
    logging.debug('CWD={}'.format(os.getcwd()))
    
    if reverse_connect:
        # Wait for incoming connection from pvserver
        con = ReverseConnect(port='31337')
    
    shot_kwargs = dict(
        ImageResolution=[print_width, print_height],
        OverrideColorPalette='PrintBackground',
        TransparentBackground=1
    )
    
    ani_kwargs = shot_kwargs.copy()
    
    if frame_window is not None:
        ani_kwargs.update(FrameWindow = frame_window)
    
    pxm = servermanager.ProxyManager()
    dir_pxy = pxm.NewProxy('misc', 'ListDirectory')
    
    def ls(path):
        dir_pxy.List(path)
        dir_pxy.UpdatePropertyInformation()
        return (
            servermanager.VectorProperty(dir_pxy, dir_pxy.GetProperty('FileList')),
            servermanager.VectorProperty(dir_pxy, dir_pxy.GetProperty('DirectoryList'))
        )
    
    # disable automatic camera reset on 'Show'
    paraview.simple._DisableFirstRenderCameraReset()

    render_view = GetActiveViewOrCreate('RenderView')
    render_view.ViewSize = [screen_width,screen_height]
    #render_view.ResetCamera()
    
    scene = GetAnimationScene()
    
    camera = GetActiveCamera()

    for tag in tags:
        # use relative paths here because absolute path might be different,
        # if this script is executed at a different machine than pvserver
        
        file_prefix = prefix + '_' + tag
        
        pvd_filename = file_prefix + '.pvd'
        pvd_path = pvd_filename
        
        (files, folders) = ls('.')
        if not pvd_filename in files:
            logging.warning('Skipping {} (File not found).'.format(pvd_path))
            continue
        
        logging.info('Loading {}'.format(pvd_path))
        pvd_file = PVDReader(FileName=pvd_path)
        pvd_file.PointArrays = ['velocity']
        pvd_file.UpdatePipeline()
        
        scene.UpdateAnimationUsingDataTimeSteps()
        
        pvd_bounds = Bounds(pvd_file.GetDataInformation().GetBounds())
        logging.debug('pvd_bounds={}'.format(str(pvd_bounds)))
        nr_of_timesteps = len(pvd_file.TimestepValues)
        logging.debug('nr_of_timesteps={}, nr_of_frames={}'.format(nr_of_timesteps,scene.NumberOfFrames))
        
        def reset_camera():
            render_view.ResetCamera()
            camera = GetActiveCamera()
            camera.SetFocalPoint(pvd_bounds.cx, pvd_bounds.cy, pvd_bounds.cz)
            camera.SetPosition(pvd_bounds.cx, pvd_bounds.cy, 6.) # TODO: How to compute z-position?
            camera.SetViewUp(0,1,0)
        
        logging.debug('Slice')
        pvd_slice = Slice(Input=pvd_file)
        pvd_slice.SliceType = 'Plane'
        pvd_slice.SliceOffsetValues = [0.0]
        pvd_slice.SliceType.Origin = [1.0, 1.0, 0.7]
        pvd_slice.SliceType.Normal = [0.0, 0.0, 0.1]
        
        pvd_slice.UpdatePipeline()
        #Hide3DWidgets(proxy=pvd_slice.SliceType)
        pvd_slice_display = Show(pvd_slice, render_view)
        pvd_slice_display.Opacity = 0.3
        
        case_filename = prefix+'.grid.case'
        case_path = case_filename
        logging.info('Loading {}'.format(case_path))
        case_file = EnSightReader(CaseFileName=case_path)
        case_file.UpdatePipeline() # required for ExtractSurface to get bounds of case file right
        case_bounds = Bounds(pvd_file.GetDataInformation().GetBounds())
        logging.debug('case_bounds={}'.format(str(case_bounds)))
        
        # https://kitware.github.io/paraview-docs/latest/python/paraview.simple.ExtractSurface.html
        logging.debug('ExtractSurface')
        case_file_surface = ExtractSurface(Input=case_file)
        case_file_surface.UpdatePipeline() # required for Clip to get bounds of ExtractSurface right
        case_file_surface.UpdatePipelineInformation()
        
        # https://kitware.github.io/paraview-docs/latest/python/paraview.simple.Clip.html
        logging.debug('Clip')
        case_file_surface_clip = Clip(Input=case_file_surface)
        case_file_surface_clip.ClipType = 'Box'
        #case_file_surface_clip.Invert = 1
        #case_file_surface_clip.Crinkleclip = 0
        #case_file_surface_clip.Exact = 0
        case_file_surface_clip.ClipType.Bounds = [ case_bounds.x0, case_bounds.x1, case_bounds.y0, case_bounds.y1 ,case_bounds.z0, case_bounds.z1 ]
        case_file_surface_clip.UpdatePipeline()
        case_file_surface_clip.UpdatePipelineInformation()
        
        case_file_surface_clip_display = Show(case_file_surface_clip, render_view)
        
        logging.debug('Render')
        render_view.Update()
        
        logging.info('preview')
        png_filename = file_prefix + '_preview.png'
        png_path = png_filename
        logging.debug(png_path)
        
        reset_camera()
        camera.Roll(180)
        camera.Elevation(-30)
        camera.Dolly(1.5)
        
        Render(render_view)
        
        SaveScreenshot(
            png_path,
            render_view,
            **{k: v for k, v in shot_kwargs.items() if v is not None}
        )
        
        for coord in velocity_coordinates:
            logging.info('Processing coordinate {}'.format(coord))
            
            ColorBy(pvd_slice_display, ('POINTS', 'velocity', coord))
            
            velocityLUT = GetColorTransferFunction('velocity')
            velocityPWF = GetOpacityTransferFunction('velocity')
            
            velocityLUTColorBar = GetScalarBar(velocityLUT, render_view)
            velocityLUTColorBar.Title = 'velocity'
            velocityLUTColorBar.ComponentTitle = coord
            velocityLUTColorBar.TitleFontFile = ''
            velocityLUTColorBar.LabelFontFile = ''
            velocityLUTColorBar.WindowLocation = 'LowerRightCorner'
            velocityLUTColorBar.ScalarBarLength = 0.5 # defaults to 0.33
            
            logging.info('Rescaling transfer function to data range..')
            pvd_slice_display.RescaleTransferFunctionToDataRange(True, False)
            pvd_slice_display.RescaleTransferFunctionToDataRange(False, True)
            
            #logging.info('Rescaling transfer function to data range over time... WARNING: This operation might take a long time!')
            #pvd_slice_display.RescaleTransferFunctionToDataRangeOverTime()
            
            # NOTE: SetScalarBarVisibility() must be called after RescaleTransferFunctionToDataRange(), 
            #       else ParaView prints warning "Failed to determine the LookupTable being used."
            pvd_slice_display.SetScalarBarVisibility(render_view, True)
            
            UpdateScalarBarsComponentTitle(velocityLUT, pvd_slice_display)
            
            logging.info('top view on slice')
            png_filename = file_prefix + '_' + str.lower(coord) + '-velocity_[1].png'
            png_path = png_filename
            logging.debug(png_path)
            
            pvd_slice_display.Opacity = 1.
            Hide(case_file_surface_clip, render_view)
            
            reset_camera()
            camera.Dolly(1.5)
            
            Render(render_view)
            
            SaveAnimation(
                png_path,
                render_view,
                **{k: v for k, v in ani_kwargs.items() if v is not None}
            )
            
            logging.info('back/side view to side mirror, slice and glyphs')
            png_filename = file_prefix + '_' + str.lower(coord) + '-velocity_[2].png'
            png_path = png_filename
            logging.debug(png_path)
            
            reset_camera()
            camera.Roll(90)
            camera.Roll(45)
            camera.Roll(90)
            camera.Elevation(-60)
            camera.Dolly(2.5)
            
            pvd_slice_display.Opacity = 0.3
            
            case_file_surface_clip_display = Show(case_file_surface_clip, render_view)
            
            pvd_glyph = Glyph(Input=pvd_slice, GlyphType='Arrow')
            #pvd_glyph.ScaleArray = ['POINTS', 'No scale array']
            #pvd_glyph.GlyphTransform = 'Transform2'
            pvd_glyph.OrientationArray = ['POINTS', 'velocity']

            pvd_glyph.Stride = 3

            pvd_glyph_display = Show(pvd_glyph, render_view)
            pvd_glyph_display.LookupTable = velocityLUT
            pvd_glyph_display.GlyphType = 'Arrow'
            pvd_glyph.MaximumNumberOfSamplePoints = 5000
            pvd_glyph.ScaleFactor = 0.05
            pvd_glyph.GlyphType.TipRadius = 0.075
            pvd_glyph.GlyphType.ShaftRadius = 0.02
            pvd_glyph.GlyphType.TipResolution = 10
            pvd_glyph.GlyphType.ShaftResolution = 5
            pvd_glyph.GlyphType.TipLength = 0.5
            
            pvd_glyph_display.SetScalarBarVisibility(render_view, True)
            
            Render(render_view)
            
            
            SaveAnimation(
                png_path,
                render_view,
                **{k: v for k, v in ani_kwargs.items() if v is not None}
            )
            
            Delete(pvd_glyph_display)
            del pvd_glyph_display
            
            Delete(pvd_glyph)
            del pvd_glyph
            
            logging.info('back/side view to side mirror, slice and stream lines')
            reset_camera()
            camera.Roll(90)
            camera.Roll(45)
            camera.Roll(75)
            camera.Elevation(-70)
            camera.Dolly(2.5)
            
            for py in [ 1., 0.9, 0.8 ]:
                for pz in [ 0.77, 0.7, 0.61 ]:
                    png_filename = file_prefix + '_' + str.lower(coord) + '-velocity_[3]_(py={},pz={}).png'.format(py,pz)
                    png_path = png_filename
                    logging.debug(png_path)
                
                    pvd_stream_tracer = StreamTracer(Input=pvd_file, SeedType='High Resolution Line Source')
                    pvd_stream_tracer.Vectors = ['POINTS', 'velocity']
                    pvd_stream_tracer.MaximumStreamlineLength = pvd_bounds.dx
                    #pvd_stream_tracer.SeedType.Point1 = [pvd_bounds.x0, 0.915*pvd_bounds.cy, 0.7]
                    #pvd_stream_tracer.SeedType.Point2 = [pvd_bounds.x1, 0.915*pvd_bounds.cy, 0.7]

                    pvd_stream_tracer.SeedType.Point1 = [pvd_bounds.x0, py, pz]
                    pvd_stream_tracer.SeedType.Point2 = [pvd_bounds.x1, py, pz]

                    pvd_stream_tracer_display = Show(pvd_stream_tracer, render_view)
                    #pvd_stream_tracer_display = GetDisplayProperties(pvd_stream_tracer, view=render_view)
                    ColorBy(pvd_stream_tracer_display, ('POINTS', 'velocity', coord))
                    pvd_stream_tracer_display.LookupTable = velocityLUT
                    pvd_stream_tracer_display.SetScalarBarVisibility(render_view, True)

                    Render(render_view)
                    
                    SaveAnimation(
                        png_path,
                        render_view,
                        **{k: v for k, v in ani_kwargs.items() if v is not None}
                    )
                    
                    Delete(pvd_stream_tracer_display)
                    del pvd_stream_tracer_display
                    
                    Delete(pvd_stream_tracer)
                    del pvd_stream_tracer
            
            if False: # TODO: Fix broken visualization
                logging.info('back/side view to side mirror, slice and Q-criterion')
                png_filename = file_prefix + '_' + str.lower(coord) + '-velocity_[4].png'
                png_path = png_filename
                logging.debug(png_path)
                
                reset_camera()
                camera.Roll(180)
                camera.Elevation(-15)
                camera.Dolly(3.5)
                
                
                # https://kitware.github.io/paraview-docs/latest/python/paraview.simple.GradientOfUnstructuredDataSet.html
                qcriterion = GradientOfUnstructuredDataSet(Input=pvd_file)
                qcriterion.ScalarArray = ['POINTS', 'velocity']
                #qcriterion.ComputeDivergence = 0
                #qcriterion.ComputeGradient = 1
                #qcriterion.ComputeVorticity = 0
                qcriterion.ComputeQCriterion = 1
                
                qcriterion.UpdatePipeline()

                # https://kitware.github.io/paraview-docs/latest/python/paraview.simple.Contour.html
                qcriterion_contour = Contour(Input=qcriterion)
                qcriterion_contour.ContourBy = ['POINTS', 'Q-criterion']
                qcriterion_contour.Isosurfaces = [4000]
                qcriterion_contour.PointMergeMethod = 'Uniform Binning'
                #qcriterion_contour.ComputeNormals = 0
                #qcriterion_contour.ComputeGradients = 0
                #qcriterion_contour.ComputeScalars = 0
                #qcriterion_contour.GenerateTriangles = 0
                
                qcriterion_contour.UpdatePipeline()

                qcriterion_contour_display = Show(qcriterion_contour, render_view)

                qcriterionLUT = GetColorTransferFunction('Qcriterion')
                qcriterionPWF = GetOpacityTransferFunction('Qcriterion')

                qcriterion_contour_display.ColorArrayName = ['POINTS', 'Q-criterion']
                qcriterion_contour_display.LookupTable = qcriterionLUT
                qcriterion_contour_display.SetScalarBarVisibility(render_view, True)
                
                Render(render_view)
                
                SaveAnimation(
                    png_path,
                    render_view,
                    **{k: v for k, v in ani_kwargs.items() if v is not None}
                )

                Delete(qcriterion_contour_display)
                del qcriterion_contour_display
                
                Delete(qcriterion_contour)
                del qcriterion_contour
                
                Delete(qcriterion)
                del qcriterion
            
            Hide(case_file_surface_clip, render_view)
        
        Delete(case_file_surface_clip)
        del case_file_surface_clip
        
        Delete(case_file_surface)
        del case_file_surface
        
        Delete(case_file)
        del case_file
        
        Delete(pvd_slice)
        del pvd_slice

        Delete(pvd_file)
        del pvd_file
