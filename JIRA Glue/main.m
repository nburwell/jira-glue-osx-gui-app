//
//  main.m
//  JIRA Glue
//
//  Created by Nick Burwell on 6/22/13.
//  Copyright (c) 2013 Burwell Designs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
