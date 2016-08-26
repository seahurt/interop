/** Filesystem utility functions
 *
 * This header provides facilities to manipulate files, directories and the paths that identify them.
 *
 *  @file
 *  @date 8/9/15
 *  @version 1.0
 *  @copyright GNU Public License.
 */
#pragma once

#include <string>

namespace illumina { namespace interop { namespace io
{
    /** Combine two directories or a directory and a filename into a file path
     *
     * This function provides a platform independent way to generate a file path. It currently supports most
     * operating systems include Mac OSX, Windows and Linux/Unix.
     *
     * @param path string representing a file path
     * @param name string representing a file or directory name to append to the end of the path
     * @return proper os-dependent file path
     */
    std::string combine(const std::string& path, const std::string& name);
    /** Get the file name from a file path
     *
     * @param source full file path
     * @return name of the file
     */
    std::string basename(std::string const& source);
    /** Get the directory name from a file path
     *
     * @param source full file path
     * @return name of the directory
     */
    std::string dirname(std::string source);
    /** Check if a file exists
     *
     * @param filename name of the file
     * @return true if the file exists and is readable
     */
    bool is_file_readable(const std::string& filename);
    /** Create a directory
     *
     * @param path path to new directory
     * @param mode linux permissions
     * @return true if directory was created
     */
    bool mkdir(const std::string& path, const int mode=0733);
}}}

