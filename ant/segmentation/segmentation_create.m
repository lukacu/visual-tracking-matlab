function [segmentation] = segmentation_create(parameters)

	segmentation.parameters = parameters;
    segmentation.map = [];

    segmentation.foreground = [];
    segmentation.background = [];
    

